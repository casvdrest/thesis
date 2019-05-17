{-# LANGUAGE OverloadedStrings #-}

module SpecIDesc where

  import           Hedgehog
  import qualified Hedgehog.Gen as Gen

  import qualified IDesc.IDesc as IDesc
  import           IDesc.Instances

  import Enumerate
  import Gen

  genNat :: MonadGen m => m Nat 
  genNat = Gen.recursive Gen.choice [ pure Zero ] [ Gen.subterm genNat Suc ]

  -- | Checks if a natural, when interpreted as an inhabitant of the Fin datatype,
  --   fits within a provided index.
  fin_ok :: Nat -> Nat -> Bool
  fin_ok n Zero = False
  fin_ok Zero (Suc i) = True
  fin_ok (Suc n) (Suc i) = fin_ok n i

  -- | Soundness property: Checks whether the values generated by some indexed generator
  --   adhere to the provided index under the given soundness predicate. 
  sound :: Show i
    => (a -> i -> Bool) -> (Ex -> i) -> Hedgehog.Gen i -> (i -> G a a) -> Int -> Property
  sound p conv gen vgen n =
    property $ do
    ix <- forAll gen
    assert (all (\x -> p x ix) (runI conv vgen ix n))

  -- | Property group for testing the indexed descriptions
  spec_group_idesc :: [(PropertyName , Property)]
  spec_group_idesc =
    [ ("genFin sound" , sound fin_ok (IDesc.unEx IDesc.asNat) genNat genFin 4 )]

  