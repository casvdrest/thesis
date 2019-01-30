{-# OPTIONS --type-in-type #-}

open import src.Gen.Base
open import src.Gen.Properties
open import src.Gen.Regular.Generic
open import src.Gen.Regular.Isomorphism
open import src.Data using (_∈_; here; Π)

open import Data.Unit
open import Data.Product
open import Data.Sum
open import Data.Nat
open import Data.List

open import Category.Monad

open import Relation.Binary.PropositionalEquality
open Relation.Binary.PropositionalEquality.≡-Reasoning

module src.Gen.Regular.Properties where

  open RawMonad ⦃...⦄ using (_⊛_; pure)

  ------ U Combinator (Unit) ------

  ugen-complete : ∀ {n : ℕ} {a : Set}  → (λ n → ugen {n} {a}) ↝ tt
  ugen-complete {n} = (n , refl) , here
  

  ------ ⊕ combinator (Coproduct) ------

  
  ⊕gen-complete-left : ∀ {n : ℕ} {a : Set} {f g : Reg}
                         {g₁ : Π ℕ (𝔾 (⟦ f ⟧ a))} {g₂ : Π ℕ (𝔾 (⟦ g ⟧ a))}
                         {x : ⟦ f ⟧ a} → g₁ ↝ x
                       -------------------------------------
                       → (λ n → ⊕gen {f = f} {g = g} (g₁ n) (g₂ n)) ↝ inj₁ x
  ⊕gen-complete-left {g₁ = g₁} {g₂ = g₂} p =
    ∥-complete-left {f = λ n → ⦇ inj₁ (g₁ n) ⦈} {g = λ n → ⦇ inj₂ (g₂ n) ⦈}
      (constr-preserves-elem {g = g₁} p)

  
  ⊕gen-complete-right : ∀ {a : Set} {f g : Reg}
                          {g₁ : Π ℕ (𝔾 (⟦ f ⟧ a))} {g₂ : Π ℕ (𝔾 (⟦ g ⟧ a))}
                        → {y : ⟦ g ⟧ a} → g₂ ↝ y
                        -------------------------------------
                        → (λ n → ⊕gen {f = f} {g = g} (g₁ n) (g₂ n)) ↝ inj₂ y
  ⊕gen-complete-right {g₁ = g₁} {g₂ = g₂} p =
    ∥-complete-right {f = λ n → ⦇ inj₁ (g₁ n) ⦈} {g = λ n → ⦇ inj₂ (g₂ n) ⦈}
      (constr-preserves-elem {g = g₂} p)
  
  
  ------ ⊗ combinator (Product) ------

  ⊗gen-complete : ∀ {n : ℕ} {a : Set} {f g : Reg}
                    {g₁ : Π ℕ (𝔾 (⟦ f ⟧ a))} {g₂ : Π ℕ (𝔾 (⟦ g ⟧ a))}
                    {x : ⟦ f ⟧ a} {y : ⟦ g ⟧ a}
                  → (p₁ : g₁ ↝ x) → (p₂ : g₂ ↝ y)
                  → depth {f = g₁} p₁ ≡ depth {f = g₂} p₂
                  --------------------------------------
                  → (λ n → ⊗gen {f = f} {g = g} (g₁ n) (g₂ n)) ↝ (x , y)
  ⊗gen-complete {g₁ = g₁} {g₂ = g₂}  p1 p2 = ⊛-complete {f = g₁} {g = g₂} p1 p2


  ------ K combinator (constants) ------

  kgen-complete : ∀ {n : ℕ} {a b : Set} {x : b} {f : ⟪ 𝔾 b ⟫}
                  → (λ n → ⟨_⟩ {n = n} f) ↝ x
                  --------------------------------------------
                  → (λ n → (kgen {a = a} {g = f})) ↝ x
  kgen-complete (p , snd) = p , snd


  ------ I combinator (constants) ------

  igen-complete : ∀ {n : ℕ} {a : Set} {f : Reg} {x : ⟦ f ⟧ a} {g : Π ℕ (𝔾 (⟦ f ⟧ a))} → g ↝ x → (λ n → igen {f = f} (g n)) ↝ x
  igen-complete p = p


  fix-lemma : ∀ {n : ℕ} {f : Reg} → ⟨ deriveGen {f = f} ⟩ (suc n , refl) ≡ deriveGen {f = f} {g = f} {n = n} ⟨ deriveGen {f = f} ⟩ (n , refl)
  fix-lemma {zero} = refl
  fix-lemma {suc n} {f} = refl

  -----
  
  complete : ∀ {n : ℕ} {f g : Reg} {x : ⟦ f ⟧ (μ g)} → (λ n → deriveGen {f = f} ⟨ deriveGen {f = g} ⟩) ↝ x
  complete {f = U} {g} {x} = ugen-complete
  complete {f = f ⊕ f₁} {g} {inj₁ x} = ⊕gen-complete-left complete
  complete {f = f ⊕ f₁} {g} {inj₂ y} = ⊕gen-complete-right complete
  complete {f = f ⊗ f₁} {g} {x} = {!⊗gen-complete!}
  complete {f = I} {g} {x} = igen-complete complete
  complete {f = K x₁} {g} {x} = kgen-complete complete
