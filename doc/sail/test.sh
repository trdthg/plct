cd ~

opam switch 5.1.0
eval $(opam env)

# sail need a way to find backends
# export SAIL=/home/trdthg/.opam/5.1.0/bin/sail
# export SAIL=$SAIL_DIR/_build/install/default/bin/sail
export SAIL_DIR=$(pwd)

# for coverage test
export PATH=$PATH:$SAIL_DIR/sailcov

case "$1" in
    coverage)
        ./test/sailcov/run_tests.py
esac
