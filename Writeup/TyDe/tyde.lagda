\documentclass[sigplan]{acmart}

\settopmatter{printacmref=false} % Removes citation information below abstract
\renewcommand\footnotetextcopyrightpermission[1]{} % removes footnote with conference information in first column
\pagestyle{plain} % removes running headers

%include agda.fmt
%include polycode.fmt
%include greek.fmt
%include colorcode.fmt

\usepackage{textcomp}

\DeclareUnicodeCharacter{10218}{$\langle\langle$}
\DeclareUnicodeCharacter{10219}{$\rangle\rangle$}
\DeclareUnicodeCharacter{7522}{\textsubscript{i}}
\DeclareUnicodeCharacter{7524}{\textsubscript{u}}
\DeclareUnicodeCharacter{8336}{\textsubscript{a}}
\DeclareUnicodeCharacter{8346}{\textsubscript{p}}
\DeclareUnicodeCharacter{10631}{$\llparenthesis$}
\DeclareUnicodeCharacter{10632}{$\rrparenthesis$}
\DeclareUnicodeCharacter{10627}{\{\!\{}
\DeclareUnicodeCharacter{10628}{\}\!\}}
\DeclareUnicodeCharacter{9656}{$\blacktriangleright$}
\DeclareUnicodeCharacter{9667}{$\triangleleft$}
\DeclareUnicodeCharacter{8347}{\textsubscript{s}}

\usepackage[font=small,labelfont=bf]{caption}

\usepackage{textgreek}

% Math
\usepackage{amssymb}
% Tables
\usepackage{amsmath}

% Colors
\usepackage{xcolor, color, colortbl}
\colorlet{gray}{gray!70}
\colorlet{green}{green!50}
\definecolor{darkblue}{HTML}{1D577A}
\definecolor{rred}{HTML}{C03425}
\definecolor{darkgreen}{HTML}{8BB523}
\definecolor{ppurple}{HTML}{6B1B7F}
\definecolor{pblack}{HTML}{000000}
\definecolor{darkyellow}{HTML}{C0B225}

% Links
\usepackage{hyperref}
\definecolor{linkcolour}{rgb}{0,0.2,0.6}
\hypersetup{colorlinks,breaklinks,urlcolor=linkcolour,linkcolor=linkcolour,citecolor=blue}

\setlength\mathindent{0.3cm}

\title{Generic Enumeration of (Indexed) Datatypes}
\author{Cas van der Rest}
\email{c.r.vanderrest@@students.uu.nl}
\affiliation{
\institution{Universiteit Utrecht}
}
\author{Wouter Swierstra}
\email{w.s.swierstra@@uu.nl}
\affiliation{
\institution{Universiteit Utrecht}
}


% Remove auto-generated ACM copyright notice
% \setcopyright{none}

\begin{document}

\maketitle

% Wouter -- ik zou het hebben over enumeration ipv generation.  dan
% maak je het nog duidelijker dat je geen random data genereert, maar
% alle elementen probeert op te sommen.

  \section*{Introduction} 

  Since the introduction of QuickCheck \cite{claessen2011quickcheck},
  \textit{property based testing} has proven to be effective for
  the discovery of bugs in programs. However, defining the
  properties to test is only part of the story: it is equally
  important to \emph{generate} suitable test data. In particular,
  requiring random test data to satisfy arbitrary preconditions can
  lead to skewed distributions---for example, naively generating
  random sorted lists will typically lead to shorter lists. As a
  result, developers need to design custom generators carefully---but
  these generators can become arbitrarily complex. When testing a
  compiler, for example, it can be quite challenging to define a good
  generator that is guaranteed to produce well-formed programs. 
  \cite{palka2011testing, claessen2015generating}
  
  In this brief abstract we propose to address this problem using the
  observation that well-formed inputs can often be described by
  (indexed) inductive datatypes. By defining a \emph{generic}
  procedure for \emph{enumerating} indexed datatypes, we can obtain a
  way of safely generating precise test data. 

  \section*{Defining generators}

  % Wouter: ik heb dit even in commentaar gezet -- hoewel
  % dit interessant is, zou ik me hier beperken tot
  % één interpretatie (lijsten) -- dat maakt het wat concreter.
  % Deze diepe(re) embedding is handig, maar voor nu een implementatie
  % detail.

  % We represent generators as a deep embedding of the combinators
  % exposed by the |Monad| and |Alternative| typeclasses, with
  % additional constructors for recursive positions, calls to other
  % generators and empty generators.

% \begin{code}
% data Gen : (a : Set) → Set where
%   Or    : ∀ {a}     → Gen a → Gen a → Gen a
%   Pure  : ∀ {a}    → a → Gen a
%   Bind  : ∀ {a b}  → Gen b → (b → Gen a) → Gen a In
%   None  : ∀ {a}    → Gen a
%   μ     : ∀ {a}    → Gen a
% \end{code}

% This results in a tree-like structure that can consequently be mapped
% to any desired interpretation.

  We will sketch how to define a generic enumerator for a collection
  of datatypes in several steps:
  \begin{itemize}
  \item We begin by defining some universe of types |U| together with
    its semantics |⟦_⟧ : U → Set|;
  \item Next, we define a datatype generic function |generate : (u :
    U) -> (n : ℕ) -> List ⟦ u ⟧|, that produces a list of elements,
    bounded by some size parameter |n|;
  \item Finally, we formulate the key \emph{completeness} property
    that we expect of our enumerators:
    \begin{code}
    ∀ u -> (x : ⟦ u ⟧) → Σ[ n ∈ ℕ ] (x ∈ generate u n)      
    \end{code}
    Simply put, this property states that for each possible value |x|,
    there is some size |n| such than |x| occurs in our enumeration.
  \end{itemize}

  We will now sketch three increasingly complex universes, together
  with their associated enumeration.
  
  \section*{Enumeration of regular types}
  % Wouter ik zou hier het data type voor Reg laten zien -- je mag
  % aannemen dat de lezer iets van generiek programmeren weet --
  % en kort uitleggen dat dit closed is under products, coproducts,
  % enz.

  Types in the universe of regular types are defined as elements of the 
  following datatype. They are closed under both products and coproducts 
  \cite{norell2008dependently}.

\begin{code}
  data Reg : Set where
    Z   : Reg 
    U   : Reg 
    _⊕_ : Reg → Reg → Reg
    _⊗_ : Reg → Reg → Reg
    I   : Reg
    K   : Set → Reg
\end{code}

  The associated semantics map values of |Reg| to a pattern functor 
  whose fixed point is isomorphic to the type that a code represents. 
  Examples of regular types and their respective codes include 
  natural numbers (|U ⊕ I|) and Lists (|U ⊕ (K a ⊗ I)|). We fix pattern 
  functors using the following fixed-point combinator:

\begin{code}
  data Fix (c : Reg) : Set where
    In : ⟦ c ⟧ (Fix c) → Fix c
\end{code}

  We can procedurally assemble generator for any type that is
  isomorphic to the fixed point of some pattern functor in two
  steps. First, we derive a generator based on the code the pattern
  functor is derived from, producing values that inhabit its
  fixed-point. Next, we travel through the appropriate isomorphism
  to obtain values of the desired type. We assume a type |Code : Set|
  that represents codes, and a meta-theory |⟦_⟧ : Code → Set → Set|,
  mapping codes to pattern functors. Enumerators for the various 
  constructions of |Reg| arise quite naturally given their semantics. 
  We refer the reader to section $3.2$ of Ulf Norell and James Chapman's 
  \textit{Dependently Typed Programming in Agda} \cite{norell2008dependently} 
  for a more in depth explanation on how to define functionality over 
  a set of types by induction on codes. We utilize a similar strategy 
  to prove that enumerators derived from codes satisfy our completeness 
  property 
  

% Unfortunately, we cannot define a function |deriveGen : (c : Code) →
% Gen (Fix c)| by induction on |c|, since |Fix c| implies that any
% recursive position in |c| is interpreted as a value of type |Fix
% c|. This becomes a problem when branching over (co)products, since the
% recursive position in both branches will refer to the fixed point of
% their respective part of the code, not the code as a whole. We can
% solve this by noting that |⟦ c ⟧ (Fix c) ≅ Fix c|, and having
% |deriveGen| yield values of type |⟦ c ⟧ (Fix c')| instead, where |c|
% is the code we are currently inducting over, and |c'| the
% \textit{top-level} code (of which |c| is a subcode). This allows us to
% induct over codes without changing the type of recursive
% positions. Calling |deriveGen| with |c ≡ c'| allows us to leverage the
% appropriate isomorphisms to obtain a generator of the desired type.
% zo'n technische detail zou ik dus weglaten -- laat op hoog niveau zien welke
% universes je bestudeert en citeer desnoods de tutorial van Ulf Norell voor
% de uitwerking

% \subsection*{Proving properties over generator interpretations}

% If we define a some generator interpretation |interpret : Gen a → T
% a|, we can use a similar approach to automatically construct a proof
% that a generic generator is well-behaved under that
% interpretation. The exact meaning of well-behaved obviously depends
% on what type |T : Set → Set| we interpret generators to.

% For example, suppose we interpret generators as functions from |ℕ|
% to |List a| (not unlike SmallCheck's |Serial| type class \cite{}). We
% might be interested in proving completeness for all derived
% generators. That is, for all values |x : a|, there exists some
% $n \in \mathbb{N}$ such that |x| is an element of the list we get by
% applying $n$ to the interpretation of |deriveGen c|, where |c| is
% the code representing a. This comes down to finding a value that
% inhabits the following type.

% \begin{code}
% ∀ {x c} → Σ[ n ∈ ℕ ] (x ∈ interpret (deriveGen c) n)
% \end{code}

% Wouter: deze sectie heb ik al kort toegelicht in hierboven en kan
% (denk ik?) weg. Geef hooguit een bewijsschets voor een of twee
% cases?

% Wouter: Weer een implementatiedetail -- dat je modulo isomorphisms werkt
% begrijpen je lezers heus wel.
% We ignore isomorphisms for a moment, but intuitively it seems
% reasonable to assume that completeness is preserved when applying a
% bijection to the values produced by a generator. By explicitly
% supplying a top-level code to |deriveGen|, we can construct the
% desired proof by induction over |c|.

  \section*{Enumeration of Indexed Containers}

  We extend the approach used for regular types to indexed types by
  applying the same techniques to two other universes capable of
  representing \emph{dependent} types. First we consider
  \textit{indexed containers} \cite{altenkirch2015indexed, dagand2017essence}. 
  Crucially, these are defined by induction over the index type.

  Indexed containers consist of a a triple of \textit{operations},
  \textit{arities} and \textit{typing}, defined as the following 
  record fields in Agda:

% Wouter: waarom geen Agda code? Hoeft niet volledig -- maar om een idee te geven?

\begin{code}
Op : i → Reg 
Ar : ∀ {x} → Fix (Op x) → Reg 
Ty : ∀ {x} {op : Fix (Op x)} → Fix (Ar op) → i 
\end{code}

  |Op i| describes the set of available operations/constructors at
  index |i|, |Ar op| the set of arities/recursive subtrees at
  operation |op|, and |Ty ar| the index of the recursive subtree at
  arity |ar|. Signatures are interpreted as a function from index to
  dependent pair, with the first element of the pair denoting a
  choice of constructor, and the second element being a function
  that describes, per arity, what the recursive subtrees of that 
  operation look like. 
  
\begin{code}
⟦ Op ◃ Ar ∣ Ty ⟧ x = 
  λ i → Σ[ op ∈ Fix (Op i) ] Π[ Fix (Ar op) ] x ∘ Ty
\end{code}
  
  Interpretations of signatures live in |I → Set|, hence we
  need adapt |Fix| accordingly. 
    
  Many familiar indexed datatypes can be described using the universe
  of indexed containers. Examples include the finite types (|Fin|),
  vectors (|Vec|), and the well-scoped lambda terms. We include an 
  example description of |Vec| below. 
  % Wouter: Kun je een voorbeeld geven van een van deze types
  % (b.v. well-scoped lambda terms) als indexed container?

  \begin{code}
  Σ-vec a = 
    let  op-vec = (λ { zero → U ; (suc x) → K a }) 
         ar-vec = (λ { {zero} _ → Z ; {suc n} _ → U })
         ty-vec = (λ { {suc n} {a} (In tt) → n })
    in  op-vec ◃ ar-vec ∣ ty-vec
  \end{code}
  
  Not all indexed families may be readily described in this
  fashion. Consider, for example, the type of binary trees indexed by
  their number of nodes:
\begin{code}
  data Tree (a : Set) : ℕ → Set where
      Leaf :  Tree a 0
      Node :  ∀ {n m} → Tree a n → a → Tree a m 
              → Tree a (suc (n + m))
\end{code}

  The dependency between |n| and |m| cannot be expressed using 
  a mapping from arity to index value, hence it is not possible 
  to describe |Tree| as an indexed container. 

%Waarom is dit geen indexed container? (Leg dit uit)

  \subsubsection*{Composing enumerators}

  We purposefully restrict the type of operations and arities to 
  the universe of regular types, since this means that we can 
  apply the techniques described in the previous section to derive 
  enumerators for indexed containers. This requires an enumerator 
  for function types. The authors of SmallCheck \cite{runciman2008smallcheck} 
  provide a good insight into how we might do this for regular types. 

  Given these ingredients, we may define enumerators for both 
  components of the dependent pair that make up a signature's 
  interpretation. 

\begin{code}
enumOp  : ∀ i →  ℕ → List ⟦ Op i ⟧
enumAr  : ∀ i → (x : ⟦ Op i⟧) 
        → ℕ → List ⟦ (y : Ar x) → Ty y ⟧ 
\end{code}

  We then sequence these operations using the monadic bind for lists 
  (|concatMap|):

\begin{code}
λ n → enumOp n >>= (λ op → op , enumAr n op)
\end{code}

  Intuitively, this defines the enumeration of a signature as the union
  of the enumerations of its operations. 

% It is possible to derive generators for datatypes that are
% isomorphic to the fixed point of the interpretation of some
% signature once we can procedurally compose generators that produce
% values that inhabit said fixed point. Before we are able to achieve
% this goal, we need to take the following two steps:

%   \begin{enumerate}
%   \item 
%   Restrict the result of |Op| and |Ar| to regular types. 
% \item Derive co-generators for regular types, e.g. generators
%   producting values of type |R → b|, where R is regular.
%   \end{enumerate}

%   Once the above is in place, we have all the ingredients necessary
%   at our disposal to derive generators from signatures. By
%   restricting operations and arities to regular types, we can simple
%   reuse the existing machinery for regular types.
%   % Wouter: kun je hier code geven? Of iets meer details? Waarom
%   % hier pseudo-mathematische notatie en elders Agda code?
    
  \section*{Indexed Descriptions}
  The universe of indexed descriptions \cite{dagand2013cosmology} makes 
  two key modifications to the universe of regular types. Recursive positions
  get an additional field storing their index, and constants may have
  descriptions depend on them.

\begin{code}
`var : (i : I) → IDesc I
`Σ : (S : Set)(T : S → IDesc I) → IDesc I
\end{code}
%Dit is niet de hele universe -- wil je die wel geven?
    Their interpretation is rather straightforward. 

\begin{code}
⟦ `var i  ⟧ r = r i
⟦ `Σ S T  ⟧ r = Σ[ s ∈ S ] ⟦ T s ⟧ r
\end{code}

  With the added |`Σ| and |`var|, we can now describe the |Tree| datatype: 

\begin{code}
tree : Set → ℕ → IDesc ℕ
tree a zero     = `1
tree a (suc n)  = `Σ (Σ (ℕ × ℕ) λ { (n' , m') → n' + m' ≡ n })
    λ { ((n , m) , refl) → `var n `× `Σ a (λ _ → `1) `× `var m }
\end{code}

  The dependency between the indices of the left- and right subtrees 
  of nodes is captured by having their description depend on a pair 
  of natural numbers together with a proof that they sum to the 
  required index. 

  \subsubsection*{Enumerating Indexed Descriptions}

  Since the |IDesc| universe largely exposes the same combinators as 
  the universe of regular types, we only really need to define 
  |generate| for the |`Σ| combinator.

\begin{code}
generate : (δ : IDesc I) → ℕ → List ⟦ δ ⟧
generate (`Σ s g) = 
  λ n → genS n >>= (λ x → x , generate (g s) n)
\end{code}

  Here, |genS : ℕ → List S| is an enumerator producing values of type S. 
  Since |S| can by any value in |Set|, we have no generic formula for 
  obtaining an appropriate enumerator. We choose to have the programmer 
  supply this enumerator, leaving the choice between any of the generic 
  approaches described here, or a custom enumerator to their judgement. 
  In the case of the |Tree| datatype, we see that this results in a neat 
  separation between the parts of an enumerator that can be derived 
  mechanically, and te parts that require more thought. 

%   We can take most of the implementation of |deriveGen| for regular
%   types to derive generators for indexed descriptions, provided we
%   lift it to the appropriate function space. This amounts to the
%   following type signature for |deriveGen|:

% \begin{code}
% deriveGen :  ∀ {φ'} → (i : I) → (φ : I → IDesc I) 
%              → Gen (⟦ φ i ⟧ (Fix φ'))
% \end{code}

%   The question remains how to handle the |`Σ| and |`var| combinators. In
%   the case of |`var|, we simply modify |Gen| such that |μ| stores the
%   index of recursive values. However, |`Σ| is a bit more tricky. We can
%   easily map the second element from |S → IDesc I| to |S →
%   Gen|. However, we have no generic procedure to derive generators for
%   arbitrary values in |Set|. This means that we need to either restrict
%   |S| to those types for which we can derive generators, or have the
%   programmer supply an appropriate generator. We opt for the second
%   solution, since it enables the programmer to guide the generation
%   process according to their needs. In the case of the |Tree| datatype,
%   this means that a programmer only needs to supply a generator that
%   calculates all the inversions of |+| while |deriveGen| takes care of
%   the rest.

\section*{Conclusion}

Using the techniques described here, we may derive generators for a large class
of indexed datatypes. Given the generic procedure to derive
generators from indexed descriptions, we can create generators for
any type that we can describe using these descriptions. This
includes types that are more way more complex than the |Tree|
example presented in this abstract, such as well-typed lambda terms,
potentially making the work presented here useful in the domain of
compiler testing.
  
\bibliographystyle{acm} % ACM-Reference-Format
\bibliography{references}
\end{document}

%%% Local Variables:
%%% mode: latex
%%% TeX-master: t
%%% TeX-command-default: "lagda2pdf"
%%% End: 

