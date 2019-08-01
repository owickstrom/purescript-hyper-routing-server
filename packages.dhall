let mkPackage =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.13.2-20190715/src/mkPackage.dhall sha256:0b197efa1d397ace6eb46b243ff2d73a3da5638d8d0ac8473e8e4a8fc528cf57

let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.13.2-20190715/src/packages.dhall sha256:906af79ba3aec7f429b107fd8d12e8a29426db8229d228c6f992b58151e2308e

let overrides =
      { trout =
            upstream.trout
         // { repo = "https://github.com/nsaunders/purescript-trout.git"
            , version = "b18b2139df19a3df7be9638595adf0e469149a4e"
            }
      }

let additions = {=}

in  upstream // overrides // additions
