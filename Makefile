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
MESOS 		?=0.11.0-incubating-RC3
BUILD_DIR	 =$(BASE_DIR)/builds/$(MESOS)

PHONY_TARGETS = boot

boot:
	@if [ ! -d $(BUILD_DIR) ]; then mkdir -p $(BUILD_DIR); fi
	@if [ ! -d $(BUILD_DIR)/m4 ]; then mkdir -p $(BUILD_DIR)/m4; fi
	@cp -r templates/* $(BUILD_DIR);
	#@mkdir $(BUILD_DIR)/m4
	@$( shell cd $(BUILD_DIR); ./bootstrap; )

#.PHONY: all 

.PHONY: $(PHONY_TARGETS)
