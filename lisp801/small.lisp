(funcall #'(setf iref)
	 #'(lambda (object) (= (ldb (cons 2 0) (ival object)) 1))
	 'consp 5)
(funcall #'(setf iref)
	 #'(lambda (new-definition function-name)
	     (if (consp function-name)
		 (funcall #'(setf iref) new-definition
			  (car (cdr function-name)) 6)
		 (progn
		   (funcall #'(setf iref) new-definition function-name 5)
		   (funcall #'(setf iref)
			    (dpb 0 '(1 . 1) (iref function-name 8))
			    function-name 8)))
	     new-definition)
	 'fdefinition 6)
(funcall #'(setf iref)
	 #'(lambda (new-function symbol &optional environment)
	     (funcall #'(setf iref) new-function symbol 5)
	     (funcall #'(setf iref) (dpb 1 '(1 . 1) (iref symbol 8))
		      symbol 8)
	     new-function)
	 'macro-function 6)
(funcall #'(setf macro-function)
	 #'(lambda (name lambda-list &rest body)
	     (list 'progn
		   (list 'funcall '#'(setf macro-function)
			 (list 'function
			       (cons 'lambda (cons lambda-list body)))
			 (list 'quote name))
		   (list 'quote name)))
	 'defmacro)
(defmacro defun (name lambda-list &rest body)
  (list 'progn
	(list 'funcall '#'(setf fdefinition)
	      (list 'function
		    (list 'lambda lambda-list
			  (cons 'block (cons (if (consp name)
						 (car (cdr name))
						 name)
					     body))))
	      (list 'quote name))
	(list 'quote name)))
(defmacro setf (place new-value)
  (if (consp place)
      (cons 'funcall (cons (list 'function (list 'setf (car place)))
			   (cons new-value (cdr place))))
      (list 'setq place new-value)))
(defun append (&rest lists)
  (if (cdr lists)
      (let ((list (car lists))
	    (result nil)
	    (end nil))
	(if list
	    (tagbody
	     start
	       (if list
		   (progn
		     (setf end (if end
				   (setf (cdr end) (list (car list)))
				   (setf result (list (car list)))))
		     (setf list (cdr list))
		     (go start)))
	       (setf (cdr end) (apply #'append (cdr lists)))
	       (return-from append result))
	    (apply #'append (cdr lists))))
      (car lists)))
(defun backquote-expand (list level)
  (if (consp list)
      (if (eq 'backquote (car list))
	  (list 'list ''backquote
		(backquote-expand (car (cdr list)) (+ level 1)))
	  (if (eq 'unquote (car list))
	      (if (= level 0)
		  (car (cdr list))
		  (list 'list ''unquote
			(backquote-expand (car (cdr list)) (- level 1))))
	      (if (eq 'unquote-splicing (car list))
		  (if (= level 0)
		      (values (car (cdr list)) t)
		      (list 'list ''unquote-splicing
			    (backquote-expand (car (cdr list)) (- level 1))))
		  (labels ((collect (list)
			     (if (consp list)
				 (cons (multiple-value-call
					   #'(lambda (value
						      &optional splicingp)
					       (if splicingp
						   value
						   (list 'list value)))
				       (backquote-expand (car list) level))
				     (collect (cdr list)))
				 (list (list 'quote list)))))
		    (cons 'append (collect list))))))
      (list 'quote list)))
(defmacro backquote (form)
  (backquote-expand form 0))
(defun macro-function (symbol &optional environment)
  "(dolist (binding environment)
    (when (and (consp (car binding))
	       (= (floor (ival (cdar binding)) 16) 1)
	       (eq (caar binding) symbol))
      (return-from macro-function 
	(when (= (ldb '(1 . 4) (ival (cdr binding))) 1)
	  (cdr binding)))))"
  (if (= (ldb '(1 . 1) (iref symbol 8)) 1)
      (iref symbol 5)))
(defun macroexpand-1 (form &optional env)
  (if (consp form)
      (let ((definition (macro-function (car form) env)))
	(if definition
	    (values (apply definition (cdr form)) t)
	    (values form nil)))
      (if (and form (symbolp form) (= (ldb '(1 . 0) (iref form 8)) 1))
	  (values (iref form 4) t)
	  (values form nil))))
(defun macroexpand (form &optional env)
  (multiple-value-bind (form expanded-p)
      (macroexpand-1 form env)
    (if expanded-p
	(tagbody
	 start
	   (multiple-value-bind (expansion expanded-p)
	       (macroexpand-1 form env)
	     (if expanded-p
		 (progn
		   (setq form expansion)
		   (go start))
		 (return-from macroexpand (values expansion t)))))
	(values form nil))))
(defmacro define-symbol-macro (symbol expansion)
  `(progn
    (setf (iref ',symbol 4) ',expansion)
    (setf (iref ',symbol 8) (dpb 1 (cons 1 0) (iref ',symbol 8)))
    ',symbol))
(defun special-operator-p (symbol)
  (member symbol '(block catch eval-when flet function go if labels let let*
		   load-time-value locally macrolet multiple-value-call
		   multiple-value-prog1 progn progv quote return-from setq
		   symbol-macrolet tagbody the throw unwind-protect)))
(defun constantp (form &optional environment)
  (not (or (and (symbolp form)
		(zerop (ldb '(1 . 8) (iref form 8))))
	   (and (consp form)
		(not (eq (car form) 'quote))))))
(defun null (object) (if object nil t))
(defun not (object) (if object nil t))
(defun length (sequence)
  (let ((tag (ldb '(2 . 0) (ival sequence))))
    (if (= tag 0)
	0
	(if (= tag 1)
	    (let ((i 0)) (dolist (elem sequence i) (setf i (+ 1 i))))
	    (if (= tag 2)
		(let ((subtag (iref sequence 1)))
		  (if (= subtag 3)
		      (/ (ival (iref sequence 0)) 256)
		      (if (= subtag 4)
			  (let ((dimensions/fill (iref sequence 3)))
			    (if (consp dimensions/fill)
				(error "not a sequence")
				(or dimensions/fill
				    (length (iref sequence 4)))))
			  0)))
		(let ((subtag (jref sequence 1)))
		  (if (= subtag 20)
		      (- (/ (jref sequence 0) 64) 4)
		      (if (= subtag 116)
			  (- (/ (jref sequence 0) 8) 31)
			  (error "not a sequence")))))))))
(defun mod (x y) (multiple-value-call #'(lambda (q r) r) (floor x y)))
(defun functionp (object) (eq (type-of object) 'function))
(defun coerce (object result-type)
  (if (typep object result-type)
      object
      (case result-type
	((t) object)
	(character (character object))
	(function (if (and (consp object) (eq (car object) 'lambda))
		      (eval (list 'function object))
		      (if (fboundp object)
			  (fdefinition object))
			  (error 'type-error :datum object
				 :expected-type result-type)))
	(t (error 'type-error :datum object :expected-type result-type)))))
(defun ensure-type (name expander)
  (let ((cons (assoc name *type-expanders*)))
    (if cons
	(setf (cdr cons) expander)
	(push (cons name expander) *type-expanders*))
    name))
(defmacro deftype (name lambda-list &rest forms)
  `(ensure-type ',name #'(lambda ,lambda-list (block ,name ,@forms))))
(defun *= (cons number)
  (or (not cons) (eq (car cons) '*) (= (car cons) number)))
(defun typep (object type-specifier &optional environment)
  (let ((tag (ldb '(2 . 0) (ival object))))
    (case type-specifier
      ((nil extended-char) nil)
      ((t *) t)
      (null (not object))
      (list (or (not object) (= tag 1)))
      (fixnum (and (= tag 0) (= (ldb '(5 . 0) (ival object)) 16)))
      (package (and (= tag 2) (= (iref object 1) 5)))
      (symbol (or (not object) (and (= tag 2) (= (iref object 1) 0))))
      ((character base-char)
       (and (= tag 0) (= (ldb '(5 . 0) (ival object)) 24)))
      (standard-char (and (= tag 0)
			  (= (ldb '(5 . 0) (ival object)) 24)
			  (let ((code (char-code object)))
			    (or (= code 10)
				(< 31 code 127)))))
      (bit (member object '(0 1)))
      (t (setq type-specifier (designator-list type-specifier))
	 (case (car type-specifier)
	   (cons (and (= tag 1)
		      (or (not (cdr type-specifier))
			  (typep (car object) (cadr type-specifier)))
		      (or (not (cddr type-specifier))
			  (typep (car object) (caddr type-specifier)))))
	   ((string base-string) (and (stringp object)
				      (*= (cdr type-specifier)
					  (length object))))
	   (satisfies (funcall (cadr type-specifier) object))
	   (member (member object (cdr type-specifier)))
	   (not (not (typep object (cadr type-specifier))))
	   (and (every #'(lambda (spec) (typep object spec))
		       (cdr type-specifier)))
	   (or (some #'(lambda (spec) (typep object spec))
		     (cdr type-specifier)))
	   (eql (eql object (cadr type-specifier)))
	   (t (when (= tag 2)
		(let ((class (iref object 1)))
		  (when (= (ldb '(2 . 0) (ival class)) 2)
		    (member (car type-specifier)
			    (mapcar #'class-name
				    (class-precedence-list class))))))))))))
(defun fboundp (function-name)
  (if (consp function-name)
      (iboundp (cadr function-name) 6)
      (iboundp function-name 5)))
(defun fdefinition (function-name)
  (if (consp function-name)
      (if (iboundp (cadr function-name) 6)
	  (iref (cadr function-name) 6)
	  (error 'undefined-error :name function-name))
      (if (iboundp function-name 5)
	  (iref function-name 5)
	  (error 'undefined-error :name function-name))))
(defun function-lambda-expression (function)
  (values (list* 'lambda (iref function 4) (iref function 5))
	  (iref function 3)
	  (iref function 6)))
(defmacro defconstant (name initial-value &optional documentation)
  `(progn
    (setf (iref ',name 4) ,initial-value)
    (setf (iref ',name 8) (dpb 1 '(1 . 4) (iref ',name 8)))
    ',name))
(defmacro defparameter (name initial-value &optional documentation)
  `(progn
    (setf (iref ',name 8) ,initial-value)
    (setf (iref ',name 8) (dpb 1 (cons 1 2) (iref ',name 8)))
    ',name))
(defparameter *type-expanders* nil)
(defconstant call-arguments-limit 65536)
(defconstant lambda-parameters-limit 65536)
(defconstant multiple-values-limit 65536)
(defconstant lambda-list-keywords
  '(&allow-other-keys &aux &body &environment &key &optional &rest &whole))
(defmacro defvar (name &rest rest)
  `(progn
    (unless (or (iboundp ',name 4) ,(not rest))
      (setf (iref ',name 4) ,(car rest)))
    (setf (iref ',name 8) (dpb 1 (cons 1 2) (iref ',name 8)))
    ',name))
(defmacro psetq (&rest rest)
  (let ((inits nil)
	(sets nil)
	(list rest))
    (tagbody
     start
       (when (cddr list)
	 (push (list (gensym) (cadr list)) inits)
	 (setq list (cddr list))
	 (go start)))
    (setq list inits)
    (tagbody
     start
       (when (cddr rest)
	 (push (caar list) sets)
	 (push (car rest) sets)
	 (setq list (cdr list))
	 (setq rest (cddr rest))
	 (go start)))
    `(let ,(reverse inits)
      (setq ,@sets ,@rest))))
(defmacro return (&optional result)
  `(return-from nil ,result))
(defmacro when (test-form &rest forms)
  `(if ,test-form (progn ,@forms)))
(defmacro unless (test-form &rest forms)
  `(if (not ,test-form) (progn ,@forms)))
(defmacro and (&rest forms)
  (if forms
      (if (cdr forms)
	  `(when ,(car forms) (and ,@(cdr forms)))
	(car forms))
    `t))
(defmacro or (&rest forms)
  (if forms
      (if (cdr forms)
	  (let ((temp (gensym)))
	    `(let ((,temp ,(car forms)))
	      (if ,temp
		  ,temp
		(or ,@(cdr forms)))))
	(car forms))
    `nil))
(defmacro cond (&rest clauses)
  (when clauses
    (if (cdar clauses)
	`(if ,(caar clauses)
	     (progn ,@(cdar clauses))
	     (cond ,@(cdr clauses)))
	`(or ,(caar clauses)
	     (cond ,@(cdr clauses))))))
(defmacro case (keyform &rest clauses)
  (let ((temp (gensym)))
    (labels ((recur (clauses)
	       (when clauses
		 (if (member (caar clauses) '(otherwise t))
		     `(progn ,@(cdar clauses))
		     `(if ,(if (listp (caar clauses))
			       `(member ,temp ',(caar clauses))
			       `(eql ,temp ',(caar clauses)))
		          (progn ,@(cdar clauses))
		          ,(recur (cdr clauses)))))))
      `(let ((,temp ,keyform))
	,(recur clauses)))))
(defun type-of (object)
  (case (ldb (cons 2 0) (ival object))
    (0 (if (eq object nil)
	   'null
	   (if (= (ldb (cons 2 3) (ival object)) 2)
	       'fixnum
	       'character)))
    (1 'cons)
    (2 (case (iref object 1)
	 (0 'symbol)
	 (3 'simple-vector)
	 (4 'array)
	 (5 'package)
	 (6 'function)
	 (t (class-name (iref object 1)))))
    (3 (case (jref object 1)
	 (20 'simple-string)
	 (84 'double)
	 (116 'simple-bit-vector)
	 (t 'file-stream)))))
(defmacro ecase (keyform &rest clauses)
  (let ((temp (gensym)))
    `(let ((,temp ,keyform))
      (case ,temp ,@clauses
	    (error 'type-error :datum ,temp
		   :expected-type `(member ,@(mapcan #'(lambda (x)
							 (if (listp (car x))
							     (car x)
							     (list (car x))))
						     clauses)))))))
(defmacro multiple-value-bind (vars values-form &rest forms)
  `(multiple-value-call #'(lambda (&optional ,@vars &rest ,(gensym))
			    ,@forms)
                        ,values-form))
(defmacro multiple-value-list (form)
  `(multiple-value-call #'list ,form))
(defun values-list (list)
  (apply #'values list))
(defmacro nth-value (n form)
  `(nth ,n (multiple-value-list ,form)))
(defmacro prog (inits &rest forms)
  `(block nil
    (let ,inits
      (tagbody ,@forms))))
(defmacro prog* (inits &rest forms)
  `(block nil
    (let* ,inits
      (tagbody ,@forms))))
(defmacro prog1 (first-form &rest forms)
  (let ((temp (gensym)))
    `(let ((,temp ,first-form))
      ,@forms
      ,temp)))
(defmacro prog2 (first-form second-form &rest forms)
  (let ((temp (gensym)))
    `(progn
      ,first-form
      (let ((,temp ,second-form))
	,@forms
	,temp))))
(defun eql (a b)
  (or (eq a b)
      (and (= (ldb '(2 . 0) (ival a)) 3)
	   (= (ldb '(2 . 0) (ival b)) 3)
	   (= (jref a 1) 84)
	   (= (jref b 1) 84)
	   (= a b))))
(defun equal (a b)
  (or (eql a b)
      (cond
	((not a) nil)
	((consp a) (and (consp b)
			(equal (car a) (car b))
			(equal (cdr a) (cdr b))))
	((stringp a) (and (stringp b)
			  (string= a b)))
	((bit-vector-p a) (and (bit-vector-p b)
			       (= (length a) (length b))
			       (dotimes (i (length a) t)
				 (when (/= (aref a i) (aref b i))
				   (return))))))))
(defun equalp (a b)
  (or (eql a b)
      (cond
	((not a) nil)
	((characterp a) (and (characterp b)
			     (char-equal a b)))
	((consp a) (and (consp b)
			(equalp (car a) (car b))
			(equalp (cdr a) (cdr b))))
	((arrayp a) (and (arrayp b)
			 (equal (array-dimensions a) (array-dimensions b))
			 (dotimes (i (apply #'* (array-dimensions a)) t)
			   (unless (equalp (row-major-aref a i)
					   (row-major-aref b i))
			     (return)))))
	((= (ldb '(2 . 0) (ival a)) 2)
	 (and (= (ldb '(2 . 0) (ival b)) 2)
	      (eq (iref a 1) (iref b 1))
	      (= (ldb '(2 . 0) (ival (iref a 1))) 2)
	      (dotimes (i (iref a 0) t)
		(unless (equalp (iref a (+ 2 i)) (iref b (+ 2 i)))
		  (return))))))))
(defun identity (object) object)
(defun complement (function)
  #'(lambda (&rest rest) (not (apply function rest))))
(defun constantly (value) #'(lambda (&rest rest) value))
(defmacro do (vars (end-test-form &rest result-forms) &rest forms)
  (let ((start (gensym))
	(inits nil)
	(steps nil))
  `(block nil
    (let ,(dolist (var vars (reverse inits))
	    (push (if (consp var)
		      (list (car var) (cadr var))
		      (list var)) inits))
      (tagbody
	 ,start
	 (if ,end-test-form (return (progn ,@result-forms)))
	 ,@forms
	 ,@(dolist (var vars (when steps `((psetq ,@(reverse steps)))))
	     (when (and (consp var) (cddr var))
	       (push (car var) steps)
	       (push (caddr var) steps)))
	 (go ,start))))))
(defmacro do* (vars (end-test-form &rest result-forms) &rest forms)
  (let ((start (gensym))
	(inits nil)
	(steps nil))
  `(block nil
    (let* ,(dolist (var vars (reverse inits))
	     (push (if (consp var)
		       (list (car var) (cadr var))
		       (list var)) inits))
      (tagbody
	 ,start
	 (if ,end-test-form (return (progn ,@result-forms)))
	 ,@forms
	 ,@(dolist (var vars (when steps `((setq ,@(reverse steps)))))
	     (when (and (consp var) (cddr var))
	       (push (car var) steps)
	       (push (caddr var) steps)))
	 (go ,start))))))
(defmacro dotimes ((var count-form &optional result-form) &rest forms)
  (let ((start (gensym))
	(count (gensym)))
    `(block nil
      (let ((,var 0)
	    (,count ,count-form))
	(tagbody
	   ,start
	   (when (< ,var ,count)
	     ,@forms
	     (incf ,var)
	     (go ,start)))
	,result-form))))
(defmacro dolist ((var list-form &optional result-form) &rest forms)
  (let ((start (gensym))
	(list (gensym)))
    `(block nil
      (let ((,list ,list-form)
	    (,var nil))
	(tagbody
	   ,start
	   (unless ,list
	     (setf ,var nil)
	     (return-from nil ,result-form))
	   (setf ,var (car ,list))
	   (setf ,list (cdr ,list))
	   ,@forms
	   (go ,start))))))
(defmacro check-type (place typespec &optional string)
  `(tagbody
    start
    (unless (typep ,place ',typespec)
      (restart-case
	  (error 'type-error :datum ,place :expected-type ',typespec)
	(store-value (value)
	  (setf ,place value)))
      (go start))))
(defun designator-condition (default-type datum arguments)
  (if (symbolp datum)
      (apply #'make-condition datum arguments)
      (if (or (stringp datum) (functionp datum))
	  (make-condition default-type
			  :format-control datum
			  :format-arguments arguments)
	  datum)))
(defun error (datum &rest arguments)
  (let ((condition (designator-condition 'simple-error datum arguments)))
    (when (typep condition *break-on-signals*)
      (invoke-debugger condition))
    (invoke-handler condition)
    (invoke-debugger condition)))
(defun cerror (continue-format-control datum &rest arguments)
  `(with-simple-restart (continue continue-format-control)
    (apply #'error datum arguments)))
(defun signal (datum &rest arguments)
  (let ((condition (designator-condition 'simple-condition datum arguments)))
    (when (typep condition *break-on-signals*)
      (invoke-debugger condition))
    (invoke-handler condition)
    nil))
(defun warn (datum &rest arguments)
  (restart-case
      (let ((warning (if (symbolp datum)
			 (apply #'make-condition 'warning datum arguments)
			 datum)))
	(signal warning)
	(print-object warning *error-output*))
    (muffle-warning () nil))
  nil)
(defun show-frame (frame index)
  (let* ((length (fref (- frame 2)))
	 (fn (fref (- frame length 3))))
    (when (and (= (ldb '(2 . 0) (ival fn)) 2) (= (iref fn 1) 6))
      (format *debug-io* "~A: (~A" index (iref fn 6))
      (dotimes (i length)
	(format *debug-io* " ~A" (fref (+ i (- frame length 2)))))
      (format *debug-io* ")~%"))))
(defun next-frame (frame)
  (- frame (fref (- frame 2)) 3))
(defun next-function-frame (frame)
  (do* ((f (next-frame frame) (next-frame f)))
       ((or (< f 6)
	    (let ((fn (fref (- f (fref (- f 2)) 3))))
	      (and (= (ldb '(2 . 0) (ival fn)) 2) (= (iref fn 1) 6))))
	(and (> f 5) f))))
(defun invoke-debugger (condition)
  (let ((debugger-hook *debugger-hook*)
	(*debugger-hook* nil))
    (when debugger-hook
      (funcall debugger-hook condition debugger-hook))
    (format *debug-io* "Entering debugger.~%")
    (princ condition *debug-io*)
    (terpri *debug-io*)
    (let ((restarts (compute-restarts condition))
	  (stack (makef))
	  (frame-depth 0)
	  (active-frame nil))
      (let ((count 0))
	(dolist (restart restarts)
	  (format *debug-io* "~A: " count)
	  (princ restart *debug-io*)
	  (terpri *debug-io*)
	  (incf count)))
      (setq active-frame (next-function-frame (- stack 20)))
      (show-frame active-frame 0)
      (tagbody
       start
	 (format *debug-io* ";~A> " frame-depth)
	 (let ((form (read)))
	   (case form
	     (:help (format *debug-io* "Type :help to get help.~%")
		    (format *debug-io* "Type :continue <index> to invoke the indexed restart.~%"))
	     (:back (do ((frame (next-function-frame (- stack 20))
				(next-function-frame frame))
			 (index 0 (+ 1 index)))
			((not frame))
		      (show-frame frame index)))
	     (:up (if (plusp frame-depth)
		      (progn
			(decf frame-depth)
			(do ((frame (next-function-frame (- stack 20))
				    (next-function-frame frame))
			     (index 0 (+ 1 index)))
			    ((= index frame-depth) (setq active-frame frame)))
			(show-frame active-frame frame-depth))
		      (format *debug-io* "Top of stack.~%")))
	     (:down (let ((frame (next-function-frame active-frame)))
		      (if frame
			  (progn
			    (incf frame-depth)
			    (setq active-frame frame)
			    (show-frame active-frame frame-depth))
			  (format *debug-io* "Bottom of stack.~%"))))
	     (:locals (do ((env (fref (- active-frame 1)) (cdr env)))
			  ((not env))
			(when (symbolp (caar env))
			  (format *debug-io* "~A~%" (caar env)))))
	     (:continue (let ((index (read)))
			  (invoke-restart-interactively (nth index restarts))))
	     (t (let ((values (multiple-value-list
			       (eval form (fref (- active-frame 1)))))
		      (count 0))
		  (if values
		      (dolist (value values)
			(format *debug-io* ";~A: ~S~%" count value)
			(incf count))
		      (format *debug-io* ";No values.~%")))))
	   (go start))))))
(defun break (&optional format-control &rest format-arguments)
  (with-simple-restart (continue "Return from BREAK.")
    (let ((*debugger-hook* nil))
      (invoke-debugger (make-condition 'simple-condition
				       :format-control format-control
				       :format-arguments format-arguments))))
  nil)
(defparameter *debugger-hook* nil)
(defparameter *break-on-signals* nil)
(defparameter *handlers* nil)