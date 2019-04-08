open import AgdaGen.Data
open import Level using (_⊔_)

open import Data.Nat hiding (_⊔_)
open import Data.Bool
open import Data.List using (List; map; [_]; concatMap; []; _∷_; _++_)
open import Data.Product using (Σ; Σ-syntax; _,_; _×_)
open import Data.Unit
open import Data.Fin hiding (lift)
open import Data.Maybe using (Maybe; just; nothing)

open import Function

open import Relation.Binary.PropositionalEquality using (_≡_; refl)

module AgdaGen.Base where

  -- The generator type. The `a` type parameter marks the output type of the
  -- generator. The resulting family is indexed by a type marking the type
  -- of values produced by recursive positions. 
  data Gen {ℓ} (a : Set ℓ) : (t : Set ℓ) → Set (Level.suc ℓ) where

    -- Marks choice between generators
    _∥_   : ∀ {t : Set ℓ} → Gen a t → Gen a t → Gen a t

    -- Applies the values generated by one generator to another
    Ap    : ∀ {t b : Set ℓ} → Gen (b → a) t → Gen b t  → Gen a t

    -- Lift a single value into the generator type
    Pure  : ∀ {t : Set ℓ} → a → Gen a t

    -- Monadic bind for generators
    Bind  : ∀ {b t : Set ℓ} → Gen b t → (b → Gen a t) → Gen a t 

      -- Generator that produces no elements at all. 
    None  : ∀ {t : Set ℓ} → Gen a t

    -- Marks a recursive positions
    μ     : Gen a a

    μ'    : ∀ {b t : Set ℓ} → (Σ[ x ∈ b ] ((Σ[ y ∈ b ] y ≡ x) → Gen a a)) → Gen a t 

    -- Call to an external generator. Using this constructor is
    -- only different from including the generator itself if the
    -- called generator contains one or more recursive
    -- positions. 
    `_    : ∀ {t : Set ℓ} → Gen a a → Gen a t

  -- Type synonym for 'closed' generators, e.g. generators whose recursive
  -- positions refer to the same type as the generator as a whole. 
  𝔾 : ∀ {ℓ} → Set ℓ → Set (Level.suc ℓ)
  𝔾 a = Gen a a
  
  -- Type synonym for 'closed' generators for function types
  co𝔾 : ∀ {ℓ} → Set ℓ → Set (Level.suc ℓ)
  co𝔾 {ℓ} a = ∀ {b : Set ℓ} → 𝔾 b → 𝔾 (a → b)

  -- Interpretation function for generators. Interprets a a value of the Gen type as a
  -- function from `ℕ` to `List a`.
  --
  -- The first parameter is the generator to be interpreted, the second parameter is a
  -- closed generator that is referred to by recursive positions.
  interpret : ∀ {ℓ} {a t : Set ℓ} → Gen a t → 𝔾 t → ℕ → List a
  interpret (g         ) tg zero = []
  interpret (g₁ ∥ g₂   ) tg (suc n) =
    merge (interpret g₁ tg (suc n)) (interpret g₂ tg (suc n))
  interpret (Ap g₁ g₂  ) tg (suc n) =
    concatMap (λ f → map f (interpret g₂ tg (suc n))) (interpret g₁ tg (suc n))
  interpret (Pure x    ) tg (suc n) = [ x ]
  interpret (Bind g₁ g₂) tg (suc n) =
    (flip concatMap) (interpret g₁ tg (suc n)) (λ x → interpret (g₂ x) tg (suc n))
  interpret (None      ) tg (suc n) = []
  interpret (μ         ) tg (suc n) =
    interpret tg tg n
  interpret (` g       ) tg (suc n) =
    interpret g g (suc n)
  interpret (μ' (x , f)) tg (suc n) = interpret (f (x , refl)) (f (x , refl)) n

  Mu : ∀ {ℓ} {i t : Set ℓ} {f : i → Set ℓ} → ((x : i) → Gen (f x) (f x)) → (x : i) → Gen (f x) t
  Mu f x = μ' (x , λ { (x , refl) → f x })

  infix 3 Mu-syntax

  Mu-syntax : ∀ {ℓ} {i t : Set ℓ} {f : i → Set ℓ} → ((x : i) → Gen (f x) (f x)) → (x : i) → Gen (f x) t
  Mu-syntax = Mu

  syntax Mu-syntax f x = μ[ f , x ]

  -- Interpret a closed generator as a function from `ℕ` to `List a`
  ⟨_⟩ : ∀ {ℓ} {a : Set ℓ} → Gen a a → ℕ → List a
  ⟨ g ⟩ = interpret g g



