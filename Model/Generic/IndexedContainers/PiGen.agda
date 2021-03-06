open import Model.Base
open import Model.Combinators

open import Model.Generic.Regular.Cogen
open import Model.Generic.Regular.Universe

open import Data.Unit
open import Data.Sum
open import Data.Product

open import Function
open import Level renaming (zero to zeroL ; suc to sucL)

-- Cogenerator for dependent function types
module Model.Generic.IndexedContainers.PiGen where

  open GApplicative ⦃...⦄
  open GAlternative ⦃...⦄
  open GMonad       ⦃...⦄

  -- Generator that generates dependent function types
  Π𝔾 : ∀ {ℓ k} → Set k → Set (sucL ℓ ⊔ sucL k)
  Π𝔾 {ℓ} {k} a = ∀ {P : a → Set ℓ} → ((x : a) → 𝔾 (λ _ → P x) tt) → 𝔾 (λ _ → (x : a) → P x) tt

  -- Dependent cogenerator for unit types
  U-PiGen : ∀ {g : Reg {0ℓ}} → Π𝔾 (⟦_⟧ {0ℓ} U ((Fix g)))
  U-PiGen gₐ = Call tt (λ _ → gₐ tt) >>= λ x → Pure {0ℓ} λ { tt → x }

  -- Dependent cogenerator for coproduct types
  ⊕-PiGen :
    ∀ {f₁ f₂ g : Reg {0ℓ}}
    → Π𝔾 {0ℓ} {0ℓ} (⟦ f₁ ⟧ (Fix g)) → Π𝔾 {0ℓ} (⟦ f₂ ⟧ (Fix g))
    → Π𝔾 {0ℓ} {0ℓ} (⟦ f₁ ⊕ f₂ ⟧ (Fix g))
  ⊕-PiGen cg₁ cg₂ gₐ =
    (Call tt (λ _ → cg₁ (λ x → gₐ (inj₁ x)))) >>= (λ f → 
    (Call tt (λ _ → cg₂ (λ y → gₐ (inj₂ y)))) >>= (λ g →
    Pure {0ℓ} λ { (inj₁ x) → f x ; (inj₂ y) → g y } ))

  -- Dependent cogenerator for product types
  ⊗-PiGen :
    ∀ {f₁ f₂ g : Reg {0ℓ}} → Π𝔾 {0ℓ} {0ℓ} (⟦ f₁ ⟧ (Fix g)) → Π𝔾 {0ℓ} {0ℓ} (⟦ f₂ ⟧ (Fix g))
    → Π𝔾 (⟦ f₁ ⊗ f₂ ⟧ (Fix g))
  ⊗-PiGen cg₁ cg₂ gₐ =
    (Call tt (λ _ → cg₁ (λ x → cg₂ λ y → gₐ (x , y)))) >>= (Pure ∘ uncurry)

  -- Dependent cogenerator for regular types
  derivePiGen :
    ∀ {f g : Reg} → RegInfo Π𝔾 f → Π𝔾 (⟦ f ⟧ (Fix g))
  derivePiGen {U} {g} info = U-PiGen {g = g}
  derivePiGen {f₁ ⊕ f₂} {g} (iₗ ⊕~ iᵣ) =
    ⊕-PiGen {f₁ = f₁} {f₂ = f₂} (derivePiGen iₗ) (derivePiGen iᵣ)
  derivePiGen {f₁ ⊗ f₂} {g} (iₗ ⊗~ iᵣ) =
    ⊗-PiGen {f₁ = f₁} {f₂ = f₂} (derivePiGen iₗ) (derivePiGen iᵣ)
  derivePiGen {I} {g} info gₐ = μ tt
  derivePiGen {K x} {g} (K~ pg) gₐ = pg gₐ
  derivePiGen {Z} Z~ = λ _ → Pure (λ ())

