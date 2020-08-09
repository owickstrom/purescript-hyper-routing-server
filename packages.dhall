let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.13.8/packages.dhall sha256:0e95ec11604dc8afc1b129c4d405dcc17290ce56d7d0665a0ff15617e32bbf03

let overrides =
      { trout =
            upstream.trout
         // { repo = "https://github.com/nsaunders/purescript-trout.git"
            , version = "b18b2139df19a3df7be9638595adf0e469149a4e"
            }
      }

let additions = {=}

in  upstream // overrides // additions
