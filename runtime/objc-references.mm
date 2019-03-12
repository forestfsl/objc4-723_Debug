/*
 * Copyright (c) 2004-2007 Apple Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
  Implementation of the weak / associative references for non-GC mode.
*/


#include "objc-private.h"
#include <objc/message.h>
#include <map>

#if _LIBCPP_VERSION
#   include <unordered_map>
#else
#   include <tr1/unordered_map>
    using namespace tr1;
#endif


// wrap all the murky C++ details in a namespace to get them out of the way.

namespace objc_references_support {
    struct DisguisedPointerEqual {
        bool operator()(uintptr_t p1, uintptr_t p2) const {
            return p1 == p2;
        }
    };
    
    struct DisguisedPointerHash {
        uintptr_t operator()(uintptr_t k) const {
            // borrowed from CFSet.c
#if __LP64__
            uintptr_t a = 0x4368726973746F70ULL;
            uintptr_t b = 0x686572204B616E65ULL;
#else
            uintptr_t a = 0x4B616E65UL;
            uintptr_t b = 0x4B616E65UL; 
#endif
            uintptr_t c = 1;
            a += k;
#if __LP64__
            a -= b; a -= c; a ^= (c >> 43);
            b -= c; b -= a; b ^= (a << 9);
            c -= a; c -= b; c ^= (b >> 8);
            a -= b; a -= c; a ^= (c >> 38);
            b -= c; b -= a; b ^= (a << 23);
            c -= a; c -= b; c ^= (b >> 5);
            a -= b; a -= c; a ^= (c >> 35);
            b -= c; b -= a; b ^= (a << 49);
            c -= a; c -= b; c ^= (b >> 11);
            a -= b; a -= c; a ^= (c >> 12);
            b -= c; b -= a; b ^= (a << 18);
            c -= a; c -= b; c ^= (b >> 22);
#else
            a -= b; a -= c; a ^= (c >> 13);
            b -= c; b -= a; b ^= (a << 8);
            c -= a; c -= b; c ^= (b >> 13);
            a -= b; a -= c; a ^= (c >> 12);
            b -= c; b -= a; b ^= (a << 16);
            c -= a; c -= b; c ^= (b >> 5);
            a -= b; a -= c; a ^= (c >> 3);
            b -= c; b -= a; b ^= (a << 10);
            c -= a; c -= b; c ^= (b >> 15);
#endif
            return c;
        }
    };
    
    struct ObjectPointerLess {
        bool operator()(const void *p1, const void *p2) const {
            return p1 < p2;
        }
    };
    
    struct ObjcPointerHash {
        uintptr_t operator()(void *p) const {
            return DisguisedPointerHash()(uintptr_t(p));
        }
    };

    // STL allocator that uses the runtime's internal allocator.
    
    template <typename T> struct ObjcAllocator {
        typedef T                 value_type;
        typedef value_type*       pointer;
        typedef const value_type *const_pointer;
        typedef value_type&       reference;
        typedef const value_type& const_reference;
        typedef size_t            size_type;
        typedef ptrdiff_t         difference_type;

        template <typename U> struct rebind { typedef ObjcAllocator<U> other; };

        template <typename U> ObjcAllocator(const ObjcAllocator<U>&) {}
        ObjcAllocator() {}
        ObjcAllocator(const ObjcAllocator&) {}
        ~ObjcAllocator() {}

        pointer address(reference x) const { return &x; }
        const_pointer address(const_reference x) const { 
            return x;
        }

        pointer allocate(size_type n, const_pointer = 0) {
            return static_cast<pointer>(::malloc(n * sizeof(T)));
        }

        void deallocate(pointer p, size_type) { ::free(p); }

        size_type max_size() const { 
            return static_cast<size_type>(-1) / sizeof(T);
        }

        void construct(pointer p, const value_type& x) { 
            new(p) value_type(x); 
        }

        void destroy(pointer p) { p->~value_type(); }

        void operator=(const ObjcAllocator&);

    };

    template<> struct ObjcAllocator<void> {
        typedef void        value_type;
        typedef void*       pointer;
        typedef const void *const_pointer;
        template <typename U> struct rebind { typedef ObjcAllocator<U> other; };
    };
  
    typedef uintptr_t disguised_ptr_t;
    inline disguised_ptr_t DISGUISE(id value) { return ~uintptr_t(value); }
    inline id UNDISGUISE(disguised_ptr_t dptr) { return id(~dptr); }
//ObjcAssociation 就是真正关联对象的类，包含了policy与及value
    class ObjcAssociation {
        uintptr_t _policy;
        id _value;
    public:
        //这种写法是C++的特性，下面的声明方法其实就是相当于
        /*
         ObjcAssociation(unitptr_t policy,id value) {
         policy = _policy(policy);
         value = _value(value)
            }
         */
        ObjcAssociation(uintptr_t policy, id value) : _policy(policy), _value(value) {}
        
        ObjcAssociation() : _policy(0), _value(nil) {}

        uintptr_t policy() const { return _policy; }
        id value() const { return _value; }
        
        bool hasValue() { return _value != nil; }
    };

#if TARGET_OS_WIN32
    typedef hash_map<void *, ObjcAssociation> ObjectAssociationMap;
    typedef hash_map<disguised_ptr_t, ObjectAssociationMap *> AssociationsHashMap;
#else
    typedef ObjcAllocator<std::pair<void * const, ObjcAssociation> > ObjectAssociationMapAllocator;
    class ObjectAssociationMap : public std::map<void *, ObjcAssociation, ObjectPointerLess, ObjectAssociationMapAllocator> {
    public:
        void *operator new(size_t n) { return ::malloc(n); }
        void operator delete(void *ptr) { ::free(ptr); }
    };
    typedef ObjcAllocator<std::pair<const disguised_ptr_t, ObjectAssociationMap*> > AssociationsHashMapAllocator;
    
    class AssociationsHashMap : public unordered_map<disguised_ptr_t, ObjectAssociationMap *, DisguisedPointerHash, DisguisedPointerEqual, AssociationsHashMapAllocator> {
    public:
        void *operator new(size_t n) { return ::malloc(n); }
        void operator delete(void *ptr) { ::free(ptr); }
    };
#endif
}

using namespace objc_references_support;

// class AssociationsManager manages a lock / hash table singleton pair.
// Allocating an instance acquires the lock, and calling its assocations()
// method lazily allocates the hash table.
//spinlock_t 自旋锁
/*
自旋锁：  自旋锁它是为为实现保护共享资源而提出一种锁机制。其实，自旋锁与互斥锁比较类似，它们都是为了解决对某项资源的互斥使用。无论是互斥锁，还是自旋锁，在任何时刻，最多只能有一个保持者，也就说，在任何时刻最多只能有一个执行单元获得锁。但是两者在调度机制上略有不同。对于互斥锁，如果资源已经被占用，资源申请者只能进入睡眠状态。但是自旋锁不会引起调用者睡眠，如果自旋锁已经被别的执行单元保持，调用者就一直循环在那里看是否该自旋锁的保持者已经释放了锁，"自旋"一词就是因此而得名
 
 原理:互斥锁一样，一个执行单元要想访问被自旋锁保护的共享资源，必须先得到锁，在访问完共享资源后，必须释放锁。如果在获取自旋锁时，没有任何执行单元保持该锁，那么将立即得到锁；如果在获取自旋锁时锁已经有保持者，那么获取锁操作将自旋在那里，直到该自旋锁的保持者释放了锁。由此我们可以看出，自旋锁是一种比较低级的保护数据结构或代码片段的原始方式，这种锁可能存在两个问题：死锁和过多占用cpu资源
 
 适用情况：自旋锁比较适用于锁使用者保持锁时间比较短的情况。正是由于自旋锁使用者一般保持锁时间非常短，因此选择自旋而不是睡眠是非常必要的，自旋锁的效率远高于互斥锁。信号量和读写信号量适合于保持时间较长的情况，它们会导致调用者睡眠，因此只能在进程上下文使用，而自旋锁适合于保持时间非常短的情况，它可以在任何上下文使用。如果被保护的共享资源只在进程上下文访问，使用信号量保护该共享资源非常合适，如果对共享资源的访问时间非常短，自旋锁也可以。但是如果被保护的共享资源需要在中断上下文访问（包括底半部即中断处理句柄和顶半部即软中断），就必须使用自旋锁。自旋锁保持期间是抢占失效的，而信号量和读写信号量保持期间是可以被抢占的。自旋锁只有在内核可抢占或SMP（多处理器）的情况下才真正需要，在单CPU且不可抢占的内核下，自旋锁的所有操作都是空操作。另外格外注意一点：自旋锁不能递归使用
 */
spinlock_t AssociationsManagerLock;

//AssociationsManager 维护了AssociationsHashMap的单例，初始化时候回调用lock.lock()方法，在析构时会调用lock.unlock(),而associations方法用于取得一个全局的AssociationsHashMap的单例
class AssociationsManager {
    // associative references: object pointer -> PtrPtrHashMap.
    static AssociationsHashMap *_map;
public:
    //这样的声明方式来源于C++
    AssociationsManager()   { AssociationsManagerLock.lock(); }
    ~AssociationsManager()  { AssociationsManagerLock.unlock(); }
    
    AssociationsHashMap &associations() {
        if (_map == NULL)
            _map = new AssociationsHashMap();
        return *_map;
    }
};

AssociationsHashMap *AssociationsManager::_map = NULL;

// expanded policy bits.

enum { 
    OBJC_ASSOCIATION_SETTER_ASSIGN      = 0,
    OBJC_ASSOCIATION_SETTER_RETAIN      = 1,
    OBJC_ASSOCIATION_SETTER_COPY        = 3,            // NOTE:  both bits are set, so we can simply test 1 bit in releaseValue below.
    OBJC_ASSOCIATION_GETTER_READ        = (0 << 8), 
    OBJC_ASSOCIATION_GETTER_RETAIN      = (1 << 8), 
    OBJC_ASSOCIATION_GETTER_AUTORELEASE = (2 << 8)
}; 

id _object_get_associative_reference(id object, void *key) {
    id value = nil;
    uintptr_t policy = OBJC_ASSOCIATION_ASSIGN;
    {
        AssociationsManager manager;
        //获取静态变量AssociationHashMap
        AssociationsHashMap &associations(manager.associations());
        disguised_ptr_t disguised_object = DISGUISE(object);
        //以 DISGUISE(object)为key查找ObjcAssociationsHashMap
        AssociationsHashMap::iterator i = associations.find(disguised_object);
        //如果关联列表存在，则根据void *key 查找ObjcAssociation
        if (i != associations.end()) {
            ObjectAssociationMap *refs = i->second;
            ObjectAssociationMap::iterator j = refs->find(key);
            //如果属性列表找到并存在，取出ObjcAssociation
            if (j != refs->end()) {
                ObjcAssociation &entry = j->second;
                value = entry.value();
                policy = entry.policy();
                //根据policy调用相应的方法
                if (policy & OBJC_ASSOCIATION_GETTER_RETAIN) {
                    objc_retain(value);
                }
            }
        }
    }
    if (value && (policy & OBJC_ASSOCIATION_GETTER_AUTORELEASE)) {
        objc_autorelease(value);
    }
    return value;
}

static id acquireValue(id value, uintptr_t policy) {
    switch (policy & 0xFF) {
    case OBJC_ASSOCIATION_SETTER_RETAIN:
        return objc_retain(value);
    case OBJC_ASSOCIATION_SETTER_COPY:
        return ((id(*)(id, SEL))objc_msgSend)(value, SEL_copy);
    }
    return value;
}

static void releaseValue(id value, uintptr_t policy) {
    if (policy & OBJC_ASSOCIATION_SETTER_RETAIN) {
        return objc_release(value);
    }
}

struct ReleaseValue {
    void operator() (ObjcAssociation &association) {
        releaseValue(association.value(), association.policy());
    }
};

//存储的大概模型就是AssociationsHasMap
//                    --------DISGUISE(obj) --- >ObjectAssociationMap
//                ObjectAssociationMap
//                        ------ @selector(hello) ObjcAssociation
//                ObjcAssociation
//                        ------ OBJC_ASSOciation_RETAIN_NONATOMIC
//                        ------ @"Hello"
void _object_set_associative_reference(id object, void *key, id value, uintptr_t policy) {
    // retain the new value (if any) outside the lock.
    //旧的关联对象，因为关联属性时，如果穿传nil，可能会调换旧的关键属性，这就是移除关联属性的时候传nil的原因，使用old_association(0,nil)创建一个临时的ObjcAssociation对象，用于持有原有的关联对象，方便在方法调用的最后释放值
    ObjcAssociation old_association(0, nil);
    id new_value = value ? acquireValue(value, policy) : nil;
    {
        //生成manager 是为了通过单例获取HashMap
        AssociationsManager manager;
        //至于为什么适用&,是想从被调用的函数中返回一个全局变量的引用（具体可以看看https://blog.csdn.net/qingkongyeyue/article/details/54344085）
/*#include <iostream.h>
        float temp; //定义全局变量temp
        float fn1(float r); //声明函数fn1
        float &fn2(float r); //声明函数fn2
        float fn1(float r) //定义函数fn1，它以返回值的方法返回函数值
        {
            　temp=(float)(r*r*3.14);
            　return temp;
        }
        float &fn2(float r) //定义函数fn2，它以引用方式返回函数值
        {
            　temp=(float)(r*r*3.14);
            　return temp;
        }
        void main() //主函数
        {
            　float a=fn1(10.0); //第1种情况，系统生成要返回值的副本（即临时变量）
            　float &b=fn1(10.0); //第2种情况，可能会出错（不同 C++系统有不同规定）
            　//不能从被调函数中返回一个临时变量或局部变量的引用
            　float c=fn2(10.0); //第3种情况，系统不生成返回值的副本
            　//可以从被调函数中返回一个全局变量的引用
            　float &d=fn2(10.0); //第4种情况，系统不生成返回值的副本
            　//可以从被调函数中返回一个全局变量的引用
            　cout<<a<<c<<d;
        }
 */
        //获取关联属性列表 ,取出来的列表是以对象为单位的 ,即某个对象的关联列表 ,这样就可以单独的关联某个对象的关联属性 而不与其他对象隔离开
        AssociationsHashMap &associations(manager.associations());
        //DISGUISE 对地址取返 将要添加关联属性的对象产生一个内存地址 做 key 存储 它的关联属性
        disguised_ptr_t disguised_object = DISGUISE(object);
        if (new_value) {
            // break any existing association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            //根据这个对象取出的这个对象关联列表存在
            if (i != associations.end()) {
                // secondary table exists
                //取出这个对象关联所有的属性列表
                ObjectAssociationMap *refs = i->second;
                //通过key，取出某个属性的关联字典，如果为空，就添加到关联字典里面，不为空就旧值进行替换
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    j->second = ObjcAssociation(policy, new_value);
                } else {
                    (*refs)[key] = ObjcAssociation(policy, new_value);
                }
            } else {
                // create the new association (first time).
                //如果key对象的字典不存在，就创建一个字典(hashMap 类似字典的功能)
                ObjectAssociationMap *refs = new ObjectAssociationMap;
                associations[disguised_object] = refs;
                //将要关联属性和策略封到一个ObjcAssociation类里面，并根据key添加到这个字典里
                (*refs)[key] = ObjcAssociation(policy, new_value);
                object->setHasAssociatedObjects();
            }
        } else {
            // setting the association to nil breaks the association.
            //如果添加关联的属性为空时，就需要取出之前关联的值，并t把它擦除掉，相当于removeObjectForKey
            //还是根据对象地址找到它的关联属性列表，然后通过key找到它关联属性的实体ObjcAssociation这个类，最后擦除掉，相当于freee从内存中移除
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i !=  associations.end()) {
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    refs->erase(j);
                }
            }
        }
    }
    // release the old value (outside of the lock).
    //如果原来的关联对象有值的话，会调用ReleaseValue()释放关联对象的值
    if (old_association.hasValue()) ReleaseValue()(old_association);
}

void _object_remove_assocations(id object) {
    vector< ObjcAssociation,ObjcAllocator<ObjcAssociation> > elements;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        if (associations.size() == 0) return;
        disguised_ptr_t disguised_object = DISGUISE(object);
        AssociationsHashMap::iterator i = associations.find(disguised_object);
        if (i != associations.end()) {
            // copy all of the associations that need to be removed.
            ObjectAssociationMap *refs = i->second;
            for (ObjectAssociationMap::iterator j = refs->begin(), end = refs->end(); j != end; ++j) {
                elements.push_back(j->second);
            }
            // remove the secondary table.
            delete refs;
            associations.erase(i);
        }
    }
//    方法会将对象包含的所有关联对象加入到一个 vector 中，然后对所有的 ObjcAssociation 对象调用 ReleaseValue() 方法，释放不再被需要的值。
    // the calls to releaseValue() happen outside of the lock.
    for_each(elements.begin(), elements.end(), ReleaseValue());
}
