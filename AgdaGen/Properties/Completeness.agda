open import AgdaGen.Base
open import AgdaGen.Combinators
open import AgdaGen.Enumerate
open import AgdaGen.Generic.Isomorphism
open import AgdaGen.Data using (_∈_; here; _⊕_; inl; inr; there; merge)

open import AgdaGen.Properties.General
open import AgdaGen.Properties.Monotonicity

open import Data.Product using (Σ; Σ-syntax; ∃; ∃-syntax; _×_; _,_; proj₁; proj₂)
open import Data.Sum hiding (map)
open import Data.List
open import Data.Nat
open import Data.Nat.Properties
open import Data.Unit hiding (_≤_)

open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym)
open Relation.Binary.PropositionalEquality.≡-Reasoning

open import Category.Functor
open import Category.Applicative
open import Category.Monad

open import Level renaming (zero to zeroL ; suc to sucL)

module AgdaGen.Properties.Completeness where

  open GApplicative ⦃...⦄
  open GAlternative ⦃...⦄

  ------ General Properties ------

  -- Generator productivity: we say that a generator produces
  -- Some value 'x' if there is some n ∈ ℕ such that 'x' is in
  -- the list we get by applying 'n' to the generator. 
  _∣_↝_ : ∀ {a t : Set} → Gen {k = 0ℓ} a t → 𝔾 t → a → Set
  f ∣ tg ↝ x = ∃[ n ] (x ∈ interpret f tg n)

  _∣ᵢ_↝_ : ∀ {I : Set} {a t : I → Set} {i : I} → Genᵢ (a i) t i → ((i : I) → 𝔾ᵢ t i) → a i → Set
  _∣ᵢ_↝_ {i = i} g tg x = ∃[ n ] (x ∈ interpretᵢ tg i g n)

  -- Completeness: A generator is complete if we can produce
  -- a productivity proof for all values of its type
  Complete : ∀ {a t : Set} → Gen a t → 𝔾 t → Set
  Complete {a} f tg = ∀ {x : a} → f ∣ tg ↝ x

  Completeᵢ : ∀ {I : Set} {a t : I → Set} {i : I} → Genᵢ (a i) t i  → ((i : I) → 𝔾ᵢ t i) → Set
  Completeᵢ {a = a} {i = i} g tg = ∀ {x : a i} → _∣ᵢ_↝_ {a = a} g tg x 

  -- Call to external generator completeness
  `-complete :
    ∀ {a t : Set} {tg : 𝔾 t} {g : 𝔾 a} {x : a}
    → g ∣ g ↝ x → (` g) ∣ tg ↝ x
  `-complete (suc n , elem) =
    suc n , elem

  Call-complete :
    ∀ {I : Set} {a : ⊤ → Set} {t : I → Set} {i : I}
      {x : a tt} {tg : (i : I) → 𝔾ᵢ t i} {g : 𝔾 (a tt)}
    → g ∣ g ↝ x
    → _∣ᵢ_↝_ {i = i} (Call g) tg x
  Call-complete (suc n , elem) =
    suc n , elem

  -- recursive positions
  μ-complete :
    ∀ {a : Set} {tg : 𝔾 a} {x : a}
    → tg ∣ tg ↝ x → μ ∣ tg ↝ x
  μ-complete (n , elem) = suc n , elem

  μᵢ-complete :
    ∀ {I : Set} {a : I → Set}
      {tg : (i : I) → 𝔾ᵢ a i} {i : I} {x : a i}
    → _∣ᵢ_↝_ {a = a} (tg i) tg x → _∣ᵢ_↝_ {a = a} (μᵢ i) tg x
  μᵢ-complete (n , elem) = (suc n) , elem  
  
  pure-complete :
    ∀ {a t : Set} {tg : 𝔾 t} {x : a} → ⦇ x ⦈ ∣ tg ↝ x
  pure-complete = 1 , here

  pureᵢ-complete :
    ∀ {I : Set} {a t : I → Set}
      {i : I} {tg : (i : I) → 𝔾ᵢ a i}  {x : a i}
    → _∣ᵢ_↝_ {a = a} ⦇ x ⦈ tg x
  pureᵢ-complete = 1 , here


  ------ Generator Choice ------

  -- Choice between two generators produces an element, given that it is
  -- produced by its left option
  ∥-complete-left :
    ∀ {a t : Set} {x : a} {f g : Gen a t} {tg : 𝔾 t}
    → f ∣ tg ↝ x
    → (f ∥ g) ∣ tg ↝ x
  ∥-complete-left (suc n , p) =
    suc n , merge-complete-left p

  ∥ᵢ-complete-left :
    ∀ {I : Set} {a t : I → Set} {i : I} {x : a i}
      {f g : Genᵢ (a i) t i} {tg : (i : I) → 𝔾ᵢ t i}
    → _∣ᵢ_↝_ {a = a} f tg x
    → _∣ᵢ_↝_ {a = a} (f ∥ g) tg x
  ∥ᵢ-complete-left (suc n , p) =
    (suc n) , merge-complete-left p

  -- Choice between two generators produces an element, given that it is produced
  -- by its right option
  ∥-complete-right :
    ∀ {a t : Set} {x : a} {f g : Gen a t} {tg : 𝔾 t}
    → g ∣ tg ↝ x
    → (f ∥ g) ∣ tg ↝ x
  ∥-complete-right (zero , ())
  ∥-complete-right (suc n , p) =
    suc n , merge-complete-right p

  ∥ᵢ-complete-right :
    ∀ {I : Set} {a t : I → Set} {i : I} {x : a i}
      {f g : Genᵢ (a i) t i} {tg : (i : I) → 𝔾ᵢ t i}
    → _∣ᵢ_↝_ {a = a} g tg x
    → _∣ᵢ_↝_ {a = a} (f ∥ g) tg x
  ∥ᵢ-complete-right (suc n , p) =
    (suc n) , merge-complete-right p

  -- If an element is produced by choice between two generators, it is either
  -- produced by the left option or by the right option
  ∥-sound :
    ∀ {a t : Set} {x : a} {n : ℕ} {f g : Gen a t} {tg : 𝔾 t}
    → (f ∥ g) ∣ tg ↝ x
    → (f ∣ tg ↝ x) ⊎ (g ∣ tg ↝ x)
  ∥-sound (zero , ())
  ∥-sound (suc n , p) =
    ⊕-bimap (λ x → suc n , x) (λ y → suc n , y) (merge-sound p)

  ∥ᵢ-sound :
    ∀ {I : Set} {a t : I → Set} {i : I} {x : a i}
      {f g : Genᵢ (a i) t i} {tg : (i : I) → 𝔾ᵢ t i}
    → _∣ᵢ_↝_ {a = a} (f ∥ g) tg x
    → (_∣ᵢ_↝_ {a = a} f tg x) ⊎ (_∣ᵢ_↝_ {a = a} g tg x)
  ∥ᵢ-sound (suc n , p) =
    ⊕-bimap (λ x → suc n , x) (λ y → suc n , y) (merge-sound p)
  
  ------ Generator Product ------
  
  -- Applying a constructor to a generator does not affect
  -- its production
  constr-preserves-elem :
    ∀ {a b t : Set} {f : a → b}
      {g : Gen a t} {tg : 𝔾 t} {x : a}
    → g ∣ tg ↝ x
    → ⦇ f g ⦈ ∣ tg ↝ f x
  constr-preserves-elem (zero , ())
  constr-preserves-elem {f = f} (suc n , elem) =
    suc n , list-ap-complete {fs = [ f ]} here elem

  constrᵢ-preserves-elem :
    ∀ {I : Set} {a b t : I → Set} {i₁ i₂ : I} {f : a i₁ → b i₂}
      {g : Genᵢ (a i₁) t i₁} {tg : (i : I) → 𝔾ᵢ t i} {x : a i₁}
    →  _∣ᵢ_↝_ {a = a} g tg x
    →  _∣ᵢ_↝_ {a = b} ⦇ f g ⦈ tg (f x)
  constrᵢ-preserves-elem {f = f} (suc n , elem) = 
    suc n , list-ap-complete {fs = [ f ]} here elem
  
  max : ℕ → ℕ → ℕ
  max zero m = m
  max (suc n) zero = suc n
  max (suc n) (suc m) = suc (max n m)

  max-zero : ∀ {n : ℕ} → max n 0 ≡ n
  max-zero {zero} = refl
  max-zero {suc n} = refl

  max-zero' : ∀ {n : ℕ} → max 0 n ≡ n
  max-zero' = refl

  max-sym : ∀ {n m} → max n m ≡ max m n
  max-sym {zero} {m} rewrite max-zero {m} = refl
  max-sym {suc n} {zero} = refl
  max-sym {suc n} {suc m} = cong suc (max-sym {n} {m})

  lemma-max₁ : ∀ {n m : ℕ} → n ≤ max n m
  lemma-max₁ {zero} {m} = z≤n
  lemma-max₁ {suc n} {zero} rewrite max-zero {n = n}
    = s≤s ≤-refl
  lemma-max₁ {suc n} {suc m} = s≤s lemma-max₁
  
  lemma-max₂ : ∀ {n m : ℕ} → m ≤ max n m
  lemma-max₂ {n} {m} rewrite max-sym {n} {m} = lemma-max₁ 
  
  -- If f produces x and g produces y, then ⦇ C f g ⦈, where C is any
  -- 2-arity constructor, produces C x y
  ⊛-complete :
    ∀ {a b c t : Set} {x : a} {y : b} {tg : 𝔾 t}
      {f : Gen a t} {g : Gen b t} {C : a → b → c}
    → (p₁ : f ∣ tg ↝ x) → (p₂ : g ∣ tg ↝ y)
    → Depth-Monotone f x tg → Depth-Monotone g y tg
    → ⦇ C f g ⦈ ∣ tg ↝ C x y
  ⊛-complete {a} {b} {c} {f = f} {g = g} {C = C}
    ((suc n) , snd₁) ((suc m) , snd₂) mt₁ mt₂  =  
    max (suc n) (suc m) , list-ap-constr {C = C}
      (mt₁ (lemma-max₁ {n = suc n} {m = suc m}) snd₁)
      (mt₂ (lemma-max₂ {n = suc n} {m = suc m}) snd₂)

  ⊛-completeᵢ :
    ∀ {I : Set} {a b c t : I → Set} {i₁ i₂ i₃ : I}
      {x : a i₁} {y : b i₂} {tg : (i : I) → 𝔾ᵢ t i}
      {f : Genᵢ (a i₁) t i₁} {g : Genᵢ (b i₂) t i₂} {C : a i₁ → b i₂ → c i₃}
    → (p₁ : _∣ᵢ_↝_ {a = a} f tg x) → (p₂ : _∣ᵢ_↝_ {a = b} g tg y)
    → Depth-Monotoneᵢ f tg x → Depth-Monotoneᵢ g tg y 
    → _∣ᵢ_↝_ {a = c} ⦇ C f g ⦈ tg (C x y)
  ⊛-completeᵢ {a} {b} {c} {f = f} {g = g} {C = C}
    ((suc n) , snd₁) ((suc m) , snd₂) mt₁ mt₂  =  
    max (suc n) (suc m) , list-ap-constr {C = C}
      (mt₁ (lemma-max₁ {n = suc n} {m = suc m}) snd₁)
      (mt₂ (lemma-max₂ {n = suc n} {m = suc m}) snd₂)
  
  ------ Combinator Completeness ------

  -- Completeness of the ∥ combinator, using coproducts to unify
  -- option types
  ∥-Complete :
    ∀ {a b t : Set} {f : Gen a t} {g : Gen b t} {tg : 𝔾 t}
    → Complete f tg → Complete g tg
    → Complete (⦇ inj₁ f ⦈ ∥ ⦇ inj₂ g ⦈) tg
  ∥-Complete {f = f} {g = g} p₁ p₂ {inj₁ x} =
    ∥-complete-left {f = ⦇ inj₁ f ⦈} {g = ⦇ inj₂ g ⦈}
    (constr-preserves-elem {g = f} p₁)
  ∥-Complete {f = f} {g = g} p₁ p₂ {inj₂ y} =
    ∥-complete-right {f = ⦇ inj₁ f ⦈} {g = ⦇ inj₂ g ⦈}
    (constr-preserves-elem {g = g} p₂)

  ∥-Completeᵢ :
    ∀ {I : Set} {a b t : I → Set} {i : I} {f : Genᵢ (a i) t i}
      {g : Genᵢ (b i) t i} {tg : (i : I) → 𝔾ᵢ t i}
    → Completeᵢ {a = a} f tg → Completeᵢ {a = b} g tg
    → Completeᵢ {a = λ i → a i ⊎ b i} (⦇ inj₁ f ⦈ ∥ ⦇ inj₂ g ⦈) tg
  ∥-Completeᵢ {a = a} {b = b} {f = f} {g = g} p₁ p₂ {inj₁ x} =
    ∥ᵢ-complete-left {a = λ i → a i ⊎ b i} {f = ⦇ inj₁ f ⦈} {g = ⦇ inj₂ g ⦈}
    (constrᵢ-preserves-elem {a = a} {b = λ i → a i ⊎ b i} {g = f} p₁)
  ∥-Completeᵢ {a = a} {b = b} {f = f} {g = g} p₁ p₂ {inj₂ y} =
    ∥ᵢ-complete-right {a = λ i → a i ⊎ b i} {f = ⦇ inj₁ f ⦈} {g = ⦇ inj₂ g ⦈}
    (constrᵢ-preserves-elem {a = b} {b = λ i → a i ⊎ b i} {g = g} p₂)

  
