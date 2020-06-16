#lang scribble/manual

@;====================================================================================================

@(require
  scribble/core
  scribble/eval
  scribble/racket
  racket
  racket/block
  "make-circuit.rkt"
  (for-label "make-circuit.rkt" racket racket/block)
  (for-template "make-circuit.rkt" racket racket/block)
  (for-syntax racket racket/block))

@(provide (all-defined-out))

@(define-syntax-rule (Interaction x ...)
  (interaction #:eval
   (make-base-eval
    #:lang '(begin
             (require racket "make-circuit.rkt" racket/block)
             (print-as-expression #f))) x ...))

@(define-syntax-rule (Interaction* x ...)
  (interaction #:eval evaller x ...))

@(define (make-evaller)
  (make-base-eval
   #:lang '(begin
            (require racket "make-circuit.rkt" racket/block)
            (print-as-expression #f))))

@(define evaller (make-evaller))
@(define (reset-Interaction*) (set! evaller (make-evaller)))
@(define-syntax-rule (Elemtag x) (add-elem-tag x))

@(define add-elem-tag
  (let ((tags '()))
   (λ ((x 'not-present))
    (cond
     ((eq? x 'not-present) tags)
     (else (set! tags (cons x tags)) (elemtag x))))))

@(define lb linebreak)
@(define nb nonbreaking)
@; ignore is a syntax such as to prevent arguments to be evaluated.
@(define-syntax-rule (ignore x ...) (void))
@; Below syntaxes are used such as to allow keyword arguments
@; without explicitly mentioning them in the definitions.
@(define-syntax-rule (nbsl x ...) (nb (seclink    x ...)))
@(define-syntax-rule (nbsr x ...) (nb (secref     x ...)))
@(define-syntax-rule (nbhl x ...) (nb (hyperlink  x ...)))
@(define-syntax-rule (nber x ...) (nb (elemref    x ...)))
@(define-syntax-rule (nbrl x ...) (nb (racketlink x ...)))
@(define-syntax-rule (nbr  x ...) (nb (racket     x ...)))
@(define-syntax-rule (nbpr x) (nber x (tt x)))
@(define-syntax-rule (defmacro x ...) (defform #:kind "macro" x ...))
@(define-syntax-rule (defmacro* x ...) (defform* #:kind "macro" x ...))
@(define (tt . content) (element 'tt (apply list content)))
@(define(minus) (tt "-"))
@(define(-?) (element "roman" ?-))
@(define (note . x) (inset (apply smaller x)))
@(define (inset . x) (apply nested #:style 'inset x))
@(define (expt-1) @↑{@(minus)1})
@(define ↑ superscript)
@(define ↓ subscript)
@(define-syntax-rule (Tabular ((e ...) ...) . rest) (tabular (list (list e ...) ...) . rest))
@(define (roman . x) (element 'roman x))
@(define (nbtt x) (nb (ttblack x)))
@(define test-arg   (make-parameter "yet to be constructed"))
@(define test-thunk (make-parameter "yet to be constructed"))
@(define test-block (make-parameter "yet to be constructed"))

@(define Void (let ((x
@seclink["void" #:doc '(lib "scribblings/reference/reference.scrbl") (tt "#<void>")]))
              (λ () x)))

@(define-syntax-rule (Tabular-with-linebreaks ((e ...) ... (le ...)) . rest)
  (Tabular (((list e (lb) (hspace 1)) ...) ... (le ...)) . rest))

@(define (make-color-style color)
  (define prop:color (color-property color))
  (define color-style (style #f (list prop:color)))
  (lambda elems (element 'roman (element color-style elems))))

@(define (make-ttcolor-style color)
  (define prop:color (color-property color))
  (define color-style (style #f (list prop:color)))
  (lambda elems (element 'tt (element color-style elems))))

@(define red       (make-color-style   "red"))
@(define green     (make-color-style   "green"))
@(define blue      (make-color-style   "blue"))
@(define black     (make-color-style   "black"))
@(define ttblack   (make-ttcolor-style "black"))
@(define ttred     (make-ttcolor-style "red"))
@(define ttgreen   (make-ttcolor-style "green"))
@(define optional "optional, evaluated, default: ")
@(define opt-proc "optional, default: ")

@(define (Rckt) (nbhl "https://docs.racket-lang.org/reference/index.html" "Racket"))

@(define (keyword . x)
  (apply seclink "keywords" #:doc '(lib "scribblings/reference/reference.scrbl") x))

@(define-syntax (make-truth-table stx)
 (syntax-case stx ()
  ((_ (in ...) expr)
 #'(let
    ((p (open-output-string))
     (table (X-sort (truth-table (in ...) expr)))
     (alignments (list (make-string (string-length (format "~s" 'in)) #\space) ...))
     (n (length '(in ...))))
    (fprintf p "~s " 'in) ...
    (fprintf p "-> ~s" 'expr)
    (define header (get-output-string p))
    (define line (make-string (string-length header) #\—))
    (file-position p 0)
    (fprintf p "~a~n~a~n~a~n" line header line)
    (for ((line (in-list table)))
     (let ((last (last line)))
      (for ((x (in-list line)) (align (in-list alignments)))
       (fprintf p "~s~a" x align))
      (fprintf p "-> ~s~n" (if (= (length last) 1) (car last) last))))
    (fprintf p "~a" line)
    (get-output-string p)))))

@(define (X-sort table) (sort table X-inputs-<?))

@(define (X-inputs-<? x y)
  (and (not (member 'X x)) (member 'X y)))

@(define-syntax SET
  (make-element-id-transformer
   (lambda _ #'(tt "set"))))

@(define-syntax ELSE
  (make-element-id-transformer
   (lambda _ #'(tt "else"))))

@(define-syntax VALUES
  (make-element-id-transformer
   (lambda _ #'(tt "values"))))

@; With thanks to Dupéron Georges
@(define (defform-remove-empty-lines the-defform)
  (define 5blanks
   (make-list 5 (paragraph (style #f '(omitable)) (element #f (list (element 'tt '(nbsp)))))))
  (match the-defform
   [(box-splice
     (list
      before ...
      (nested-flow nf-style
       (list
        (table t-style
         (list other ...
          (list
           (table (style "specgrammar" tspec-style)
           (list lines ...)))
          more ...))))
      after ...))
    (define without-empty-lines
     ;; an empty lines is a sequence of five empty columns:
     (remove* (list 5blanks) lines))
    (box-splice
     (append
      before
      (list
       (nested-flow nf-style
        (list
         (table t-style
          (append other
           (list
            (list (table (style "specgrammar" tspec-style) without-empty-lines))) more)))))
      after))]))
