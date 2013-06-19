# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

BASE_DIR	 =$(shell pwd)
BUILD_DIR	 =$(BASE_DIR)/build-spaces/$(MESOS_TAG)

.PHONY: build

build: check-env clone-mesos pull-mesos
	@if [ ! -d $(BUILD_DIR) ]; then mkdir -p $(BUILD_DIR); fi
	@if [ ! -d $(BUILD_DIR)/m4 ];  then mkdir -p $(BUILD_DIR)/m4; fi
	# Copy Mesos Codebase and checkout the specific tag.
	@if [ -d $(BUILD_DIR)/tmp ]; then rm -rf $(BUILD_DIR)/tmp; fi
	@mkdir $(BUILD_DIR)/tmp
	@cp -r repo/incubator-mesos $(BUILD_DIR)/tmp
	@cd $(BUILD_DIR)/tmp/incubator-mesos; \
		git checkout $(MESOS_TAG); \
		rm -rf .git;
	# Tar the Tag
	@cd $(BUILD_DIR)/tmp; \
		mv incubator-mesos incubator-mesos-$(MESOS_TAG); \
		tar cvfz incubator-mesos-$(MESOS_TAG).tgz . ; \
	# Copy to sources.
	@if [ -d $(BUILD_DIR)/src ]; then rm -rf $(BUILD_DIR)/src; fi
	@mkdir $(BUILD_DIR)/src
	@mv $(BUILD_DIR)/tmp/*.tgz $(BUILD_DIR)/src
	# Copy templates.
	@cp -r templates/* $(BUILD_DIR);
	@cd $(BUILD_DIR); \
		./bootstrap

clone-mesos:
	@cd rep; \
		if [ ! -d "incubator-mesos" ]; then \
			git clone git@github.com:Guavus/incubator-mesos.git; \
		fi

show-mesos-tags: pull-mesos
	@echo "Incubator-Mesos Tag List:"
	@cd repo/incubator-mesos; \
		git tag --list

pull-mesos:
	@echo "Pulling Incubator Mesos:"
	@cd repo/incubator-mesos; \
		git pull --all; \
		git fetch --tags;


check-env:
ifndef MESOS_TAG
		$(error MESOS_TAG is undefined please specify one. Tags Available)
		$(MAKE) show-mesos-tags
endif
		@echo "MESOS_TAG:$(MESOS_TAG)"
	
