(cl:defpackage :access-test
  (:use #:cl #:iterate #:lisp-unit2)
  (:use #:access)
  (:import-from #:alexandria
                #:plist-hash-table
                #:hash-table-keys
                #:copy-hash-table))

;; for a specific test
(cl:defpackage :access-test-other)

(in-package :access-test)

(enable-dot-syntax)

(defclass mop-test-object ()
  ((slot-a :accessor slot-a :initarg :slot-a :initform nil)
   (slot-b :accessor slot-b :initarg :slot-b :initform nil)
   (slot-c :accessor slot-c :initarg :slot-c :initform nil)))

(defparameter +mop+ (make-instance 'mop-test-object))

(defun run-all-tests ()
  (run-tests :package :access-test
             :name :access
             :run-contexts #'with-summary-context))

(defun run-a-test (test)
  (with-summary (:name :access)
    (run-tests :tests test)))


(defparameter +al+ `((:one . 1) ("two" . 2) ("three" . 3) (four . 4) (:5 . 5) (:something . nil)))
(defparameter +pl+ (list :one 1 "two" 2 "three" 3 'four 4 :5 5 :something nil))
(defparameter +ht+
  (plist-hash-table
   (list "one" 1 "two" 2 "three" 3 "four" 4 "5" 5 "something" nil)
   :test 'equalp))

(defclass access-test ()
  ((one :accessor one :initarg :one :initform 1)
   (two :accessor two :initarg :two :initform 2)
   (three :accessor three :initarg :three :initform 3)
   (four :initarg :four :initform 4)
   (five :initarg :five :initform 5)
   (null-slot :initarg :null-slot :initform ())
   (pl :initarg :pl :initform (copy-list +pl+) :accessor pl)))

(defun make-obj () (make-instance 'access-test))

(define-test access-basic ()
  (let ((o (make-obj)))
    (assert-equal 6 (access +al+ 'length))
    (assert-equal 3 (access +al+ 'three))
    (multiple-value-bind (value present-p) (access +al+ :something)
      (assert-equal value nil)
      (assert-equal present-p t))
    (multiple-value-bind (value present-p) (access +al+ :nothing)
      (assert-equal value nil)
      (assert-equal present-p nil))
    (assert-equal 3 (access +pl+ 'three))
    (multiple-value-bind (value present-p) (access +pl+ :something)
      (assert-equal value nil)
      (assert-equal present-p t))
    (multiple-value-bind (value present-p) (access +pl+ :nothing)
      (assert-equal value nil)
      (assert-equal present-p nil))
    (assert-equal 3 (access o 'three))
    (assert-equal 3 (access +ht+ 'three))
    (multiple-value-bind (value present-p) (access +ht+ "something")
      (assert-equal value nil)
      (assert-equal present-p t))
    (multiple-value-bind (value present-p) (access +ht+ :nothing)
      (assert-equal value nil)
      (assert-equal present-p nil))
    (assert-equal
     (list "5" "four" "one" "something" "three" "two")
     (sort (access +ht+ 'hash-table-keys) 'string<))
    (assert-equal 3 (accesses o 'pl 'three ))))

(define-test test-with-access ()
  (let ((o (make-obj)))
    (with-access (one two (my-three three))
        o
      (assert-equal 1 one)
      (assert-equal 2 two)
      (assert-equal 3 my-three)
      (setf my-three 33)
      (assert-equal 33 my-three)
      (assert-equal 33 (access o 'three))
      (setf my-three 3)
      )))

(define-test access-and-setting-alist ()
  (let ((al (copy-alist +al+)))
    (assert-equal 3 (access al 'three) "inited correctly")
    (setf (access al 'three) 333)
    (assert-equal 333 (access al 'three) "first set")
    (setf (access al 'three) 3)
    (assert-equal nil (access al 'sixteen)  "key missing")
    (setf (access al 'sixteen) 16)
    (assert-equal 16 (access al 'sixteen) "new key set"))
  )

(define-test access-and-setting-plist ()
  (let ((pl (copy-list +pl+)))
    (assert-equal 3 (access pl 'three))
    (setf (access pl 'three) 333)
    (assert-equal 333 (access pl 'three))
    (assert-equal nil (access pl 'sixteen))
    (setf (access pl 'sixteen) 16)
    (assert-equal 16 (access pl 'sixteen))))

(define-test access-and-setting-hashtable ()
  (let ((+ht+ (copy-hash-table +ht+) ))
    (assert-equal 3 (access +ht+ 'three))
    (setf (access +ht+ 'three) 333)
    (assert-equal 333 (access +ht+ 'three))
    (assert-equal 333 (access +ht+ "three"))
    (setf (access +ht+ 'three) 3)

    (assert-equal nil (access +ht+ "sixteen"))
    (setf (access +ht+ "sixteen") 16)
    (assert-equal 16 (access +ht+ 'sixteen))
    (assert-equal 16 (access +ht+ "sixteen"))
    (remhash "sixteen" +ht+)))

(define-test access-and-setting-object ()
  (let ((o (make-obj)))
    (assert-equal nil (access o 'null-slot))
    (setf (accesses o 'null-slot 'not-a-fn) 'any-more)
    (assert-equal 'any-more (accesses o 'null-slot 'not-a-fn))
    (assert-equal 1 (access o 'one))
    (assert-equal 4 (access o 'four))
    (setf (access o 'four) 444
          (access o 'one) 111)
    (assert-equal 111 (access o 'one))
    (assert-equal 444 (access o 'four))
    (setf (access o 'four) 4
          (access o 'one) 1)
    (assert-equal nil (access o 'nothing))
    (setf (access o 'nothing) 10000)
    (assert-equal nil (access o 'nothing))))

(define-test setting-object-attributes ()
  (let ((o (make-obj)))
    (assert-equal 1 (accesses o 'pl :one) o (pl o))
    (setf (accesses o 'pl :one) 111)
    (assert-equal 111 (accesses o 'pl :one)  o (pl o))
    (setf (accesses o 'pl :one) 1)
    (assert-equal 1 (accesses o 'pl :one)  o (pl o))
    (assert-equal nil (accesses o 'pl :twenty)  o (pl o))
    (setf (accesses o 'pl :twenty) 20)
    (assert-equal 20 (accesses o 'pl :twenty)  o (pl o))
    (setf (accesses o 'pl :twenty) nil)
    (assert-equal nil (accesses o 'pl :twenty)  o (pl o))
    ))


(define-test dot-basic ()
  (let ((o (make-obj)))
    (with-dot ()
      (assert-equal 6 +al+.length)
      (assert-equal 3 +al+.three)
      (assert-equal 3 +pl+.three)
      (assert-equal 3 o.three)
      (assert-equal 3 o.pl.three))))

(define-test dot-set ()
  (let ((o (make-obj)))
    (with-dot ()
      (assert-equal 6 +al+.length)
      (assert-equal 3 +al+.three)
      (setf +al+.three 333)
      (assert-equal 333 +al+.three)
      (setf +al+.three 3)
      (assert-equal 3 o.pl.three)
      (setf o.pl.three 333)
      (assert-equal 333 o.pl.three)
      (setf o.pl.three 3)
      )))

(define-test dot-basic-reader ()
  (let ((o (make-obj)))
    (assert-equal 6 #D+al+.length)
    (assert-equal 3 #D+al+.three)
    (assert-equal 3 #D+pl+.three)
    (assert-equal 3 #Do.three)
    (assert-equal 3 #Do.pl.three)
    #D(let ((l (list 1 2 3 4 5)))
        (assert-equal 5 l.length)
        (assert-equal 6 +al+.length)
        (assert-equal 3 +al+.three)
        (assert-equal 3 +pl+.three)
        (assert-equal 3 o.three)
        (assert-equal 3 o.pl.three))))

(define-test dot-iteration ()
  (with-dot ()
    (iter (for (k v . rest) on (list :pl1 +pl+ :pl2 +pl+) by #'cddr)
      (declare (ignorable k))
      (when (first-iteration-p)
        (assert-equal 12 rest.pl2.length)
        (assert-equal 4 rest.pl2.four))
      (assert-equal 4 v.four))))

;; sbcl started raising (rightly) style warnings about this
(handler-bind ((style-warning #'muffle-warning))
  (defclass multi-package-test-obj ()
    ((my-slot :accessor my-slot :initarg :my-slot :initform nil)
     (access-test-other::my-slot :accessor access-test-other::my-slot
                                 :initarg :my-slot :initform nil))
    (:documentation "Do you hate sanity?"))
  (c2mop:finalize-inheritance (find-class 'multi-package-test-obj)))

(define-test has-slot-test ()
  (let ((o (make-instance 'multi-package-test-obj)))
    (assert-warning 'access-warning
      ;; seems like this *could be* implementation dependent based on the ordering returned from
      ;; the mop... Lets hope for the sanest (eg first listed)
      (assert-eql 'my-slot (has-slot? o :my-slot)))
    (assert-no-warning 'access-warning
      (assert-eql 'my-slot (has-slot? o 'my-slot)))
    (assert-no-warning 'access-warning
      (assert-eql 'access-test-other::my-slot (has-slot? o 'access-test-other::my-slot)))))

(define-test has-slot?2 ()
  (assert-true (has-slot? +mop+ 'slot-a))
  (assert-true (has-slot? +mop+ :slot-a))
  (assert-true (has-slot? +mop+ "slot-a"))
  (assert-false (has-slot? +mop+ "slot-d"))
  (assert-false (has-slot? +mop+ 'slot-d))
  (assert-false (has-slot? +mop+ :slot-d)))

(defclass accessed-object ()
  ((my-slot :initarg :my-slot :initform nil)
   (no-access :initarg :no-access :initform nil)
   (call-number :accessor call-number :initarg :call-number :initform 0)))

(defmethod my-slot ((o accessed-object))
  (incf (call-number o))
  (slot-value o 'my-slot))

(defmethod (setf my-slot) (new (o accessed-object))
  (incf (call-number o))
  (setf (slot-value o 'my-slot) new ))

(define-test ensure-called-when-you-can ()
  (let ((o (make-instance 'accessed-object)))
    (setf (access o :my-slot) :test)
    (assert-eql 1 (call-number o))
    (assert-eql :test (access o :my-slot))
    (assert-eql 2 (call-number o))

    ;; check that accessorless slots still work correctly
    (setf (access o :no-access) :test2)
    (assert-eql :test2 (access o :no-access) :slot-access-by-name-failed)

    ;; check that accessorless slots still work correctly
    (setf (access o 'no-access) :test3)
    (assert-eql :test3 (access o 'no-access) :slot-access-failed)
    ))

(defclass slot-def-test-obj ()
  ((acctexp :accessor acctexp :initarg :acctexp :initform nil)
   (acct :accessor acct :initarg :acct :initform nil)
   (acctexp2 :accessor acctexp2 :initarg :acctexp2 :initform nil)))

(define-test slot-definition-tests ()
  (let* ((o (make-instance 'slot-def-test-obj :acct 1008 :acctexp "1/1/2009" :acctexp2 "1/1/2011"))
         (s (class-slot-by-name o "acct")))
    (assert-eql 'acct (has-slot? o s))
    (assert-eql #'(setf acct) (has-writer? o `(setf acct)))
    (assert-eql #'(setf acct) (has-writer? o s))
    (assert-eql #'(setf acct) (has-writer? o #'(setf acct)))
    (assert-eql #'acct (has-reader? o s))
    (assert-eql 1008 (access o s))))


(define-test test-has-reader? ()
  (assert-true (has-reader? +mop+ #'slot-a))
  (assert-true (has-reader? +mop+ 'slot-a))
  (assert-true (has-reader? +mop+ :slot-a))
  (assert-true (has-reader? +mop+ "slot-a"))
  (assert-false (has-reader? +mop+ "slot-d"))
  (assert-false (has-reader? +mop+ 'slot-d))
  (assert-false (has-reader? +mop+ :slot-d)))

(define-test test-has-writer? ()
  (assert-true (has-writer? +mop+ #'(setf slot-a)))
  (assert-true (has-writer? +mop+ 'slot-a))
  (assert-true (has-writer? +mop+ :slot-a))
  (assert-true (has-writer? +mop+ "slot-a"))

  (assert-true (has-writer? +mop+ '(setf slot-a)))
  (assert-true (has-writer? +mop+ '(setf :slot-a)))
  (assert-true (has-writer? +mop+ '(setf "slot-a")))
  (assert-true (has-writer? +mop+ "(setf slot-a)"))

  (assert-false (has-writer? +mop+ "slot-d"))
  (assert-false (has-writer? +mop+ 'slot-d))
  (assert-false (has-writer? +mop+ :slot-d)))

(define-test deep-null-alist ()
  (let ((o (make-obj)))
    (setf (accesses o 'pl '(:my-new-alist :type :plist) '(:a :type :alist)) "a")
    (assert-equal "a" (accesses o 'pl '(:my-new-alist :type :plist) '(:a :type :alist)))
    (assert-equal '((:a . "a")) (accesses o 'pl '(:my-new-alist :type :plist)))
    (setf (accesses o 'pl '(:my-new-alist :type :plist) '("b" :type :alist)) 'b)
    (assert-equal 'b (accesses o 'pl '(:my-new-alist :type :plist) '("b" :type :alist)))

    (setf (accesses o 'pl) nil)

    (setf (accesses o 'pl '(:my-new-alist :type :plist) '(:a :type :alist)) "a")
    (assert-equal "a" (accesses o 'pl '(:my-new-alist :type :plist) '(:a :type :alist)))
    (assert-equal '((:a . "a")) (accesses o 'pl '(:my-new-alist :type :plist)))
    (setf (accesses o 'pl '(:my-new-alist :type :plist) '("b" :type :alist)) 'b)
    (assert-equal 'b (accesses o 'pl '(:my-new-alist :type :plist) '("b" :type :alist)))))

(define-test deep-null-dictionary-instantiation ()
  (let ( ht arr ht2 alist val )
    (setf (access:accesses
           ht
           '(:da :type :hash-table :test 'equalp)
           '(5 :type :array)
           '(:key :type :hash-table)
           '("aa" :type :alist))
          42)
    (setf arr (gethash :da ht)
          ht2 (aref arr 5)
          alist (gethash :key ht2)
          val (cdr (assoc "aa" alist :test #'equalp)))
    (assert-typep 'hash-table ht)
    (assert-typep 'array arr)
    (assert-typep 'hash-table ht2)
    (assert-typep 'list alist)
    (assert-eql 42 val)
    (assert-eql 42 (accesses ht :da 5 :key "aa"))))

(define-test null-plists-instantiation ()
  (let (it)
    (setf (access:accesses it :a :b) 3)
    (assert-equal `(:a (:b 3)) it)))
