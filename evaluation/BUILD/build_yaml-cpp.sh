#!/bin/bash

# For Mac
if [ $(command uname) = "Darwin" ]; then
	if ! [ -x "$(command -v greadlink)"  ]; then
		brew install coreutils
	fi
	BIN_PATH=$(greadlink -f "$0")
	ROOT_DIR=$(dirname $(dirname $(dirname $BIN_PATH)))
# For Linux
else
	BIN_PATH=$(readlink -f "$0")
	ROOT_DIR=$(dirname $(dirname $(dirname $BIN_PATH)))
fi

if ! [ -d "${ROOT_DIR}/tool/MemLock/build/bin" ]; then
	${ROOT_DIR}/tool/install_MemLock.sh
fi

if ! [ -d "${ROOT_DIR}/tool/AFL-2.52b/build/bin" ]; then
	${ROOT_DIR}/tool/install_MemLock.sh
fi

PATH_SAVE=$PATH
LD_SAVE=$LD_LIBRARY_PATH

export PATH=${ROOT_DIR}/clang+llvm/bin:$PATH
export LD_LIBRARY_PATH=${ROOT_DIR}/clang+llvm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

if ! [ $(command llvm-config --version) = "6.0.1" ]; then
	echo ""
	echo "You can simply run tool/build_MemLock.sh to build the environment."
	echo ""
	echo "Please set:"
	echo "export PATH=$PREFIX/clang+llvm/bin:\$PATH"
	echo "export LD_LIBRARY_PATH=$PREFIX/clang+llvm/lib:\$LD_LIBRARY_PATH"
elif ! [ -d "${ROOT_DIR}/clang+llvm"  ]; then
	echo ""
	echo "You can simply run tool/build_MemLock.sh to build the environment."
	echo ""
	echo "Please set:"
	echo "export PATH=$PREFIX/clang+llvm/bin:\$PATH"
	echo "export LD_LIBRARY_PATH=$PREFIX/clang+llvm/lib:\$LD_LIBRARY_PATH"
else
	echo "start ..."
	cd ${ROOT_DIR}/evaluation/BUILD/yaml-cpp
	git clone https://github.com/jbeder/yaml-cpp SRC
	cd SRC
	git checkout 562aefc114938e388457e6a531ed7b54d9dc1b62
	cd ..
	rm -rf $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock
	rm -rf $(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL
	mv $(dirname ${BIN_PATH})/yaml-cpp/SRC $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock
	cp -rf $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock $(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL

	#build MemLock project
	export AFL_PATH=${ROOT_DIR}/tool/MemLock
	cd $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock
	if [ -d "$(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock/build"  ]; then
		rm -rf $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock/build
	fi
	mkdir $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock/build
	cd $(dirname ${BIN_PATH})/yaml-cpp/SRC_MemLock/build
	export CC=${ROOT_DIR}/tool/MemLock/build/bin/memlock-stack-clang
	export CXX=${ROOT_DIR}/tool/MemLock/build/bin/memlock-stack-clang++
	export CFLAGS="-g -O0 -fsanitize=address"
	export CXXFLAGS="-g -O0 -fsanitize=address"
	cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF ..
	make

	#build AFL project
	export AFL_PATH=${ROOT_DIR}/tool/AFL-2.52b
	cd $(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL
	if [ -d "$(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL/build"  ]; then
		rm -rf $(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL/build
	fi
	mkdir $(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL/build
	cd $(dirname ${BIN_PATH})/yaml-cpp/SRC_AFL/build
	export CC=${ROOT_DIR}/tool/AFL-2.52b/build/bin/afl-clang-fast
	export CXX=${ROOT_DIR}/tool/AFL-2.52b/build/bin/afl-clang-fast++
	export CFLAGS="-g -O0 -fsanitize=address"
	export CXXFLAGS="-g -O0 -fsanitize=address"
	cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF ..
	make

	export PATH=${PATH_SAVE}
	export LD_LIBRARY_PATH=${LD_SAVE}
fi
