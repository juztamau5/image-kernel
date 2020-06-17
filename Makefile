# Copyright 2019 Cartesi Pte. Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

.PHONY: all build push run pull share copy

TAG ?= latest
TOOLCHAIN_TAG ?= 0.2.0
KERNEL_VERSION ?= 5.5.19-ctsi-1-rc1
RISCV_PK_VERSION ?= 1.0.0-ctsi-1-rc1

CONTAINER_BASE := /opt/cartesi/image-linux-kernel

IMG:=cartesi/linux-kernel:$(TAG)
BASE:=/opt/riscv
LINUX_KERNEL:=$(BASE)/kernel/artifacts/linux-${KERNEL_VERSION}.bin
LINUX_HEADERS:=$(BASE)/kernel/artifacts/linux-headers-${KERNEL_VERSION}.tar.xz

BUILD_ARGS :=

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS += --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

ifneq ($(KERNEL_VERSION),)
BUILD_ARGS += --build-arg KERNEL_VERSION=$(KERNEL_VERSION)
endif

ifneq ($(RISCV_PK_VERSION),)
BUILD_ARGS += --build-arg RISCV_PK_VERSION=$(RISCV_PK_VERSION)
endif

all: copy

build:
	docker build -t $(IMG) $(BUILD_ARGS) .

push:
	docker push $(IMG)

pull:
	docker pull $(IMG)

run:
	docker run --hostname toolchain-env -it --rm \
		-e USER=$$(id -u -n) \
		-e GROUP=$$(id -g -n) \
		-e UID=$$(id -u) \
		-e GID=$$(id -g) \
		-v `pwd`:$(CONTAINER_BASE) \
		-w $(CONTAINER_BASE) \
		$(IMG) $(CONTAINER_COMMAND)

run-as-root:
	docker run --hostname toolchain-env -it --rm \
		-v `pwd`:$(CONTAINER_BASE) \
		$(IMG) $(CONTAINER_COMMAND)

copy: build
	ID=`docker create $(IMG)` && docker cp $$ID:$(LINUX_KERNEL) . && docker cp $$ID:$(LINUX_HEADERS) . && docker rm -v $$ID
