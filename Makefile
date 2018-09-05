# Makefile for zookeeper-authorizers RPM.

PWD=$(shell pwd)

BLD=$(PWD)/build
RPMDIR=$(BLD)/rpms
JARCACHE=$(BLD)/m2

REPO_TAG=$(shell git describe --tags HEAD --long)
REPO_TAGFMT=$(shell echo ${REPO_TAG} | sed 's/-g/-/')
REPO_VER=$(shell echo ${REPO_TAGFMT} | cut -d '-' -f 1)
REPO_REL=$(shell echo ${REPO_TAGFMT} | cut -d '-' -f 2,3 | sed 's/-/_/')

clean:
	rm -rf $(BLD)

upload_jarcache:
	[ ! -z $(jarcache_dir) ] || echo must run make upload_jarcache jarcache_dir=...
	aws s3 sync $(jarcache_dir) $(S3_JAR_CACHE)

sync_jarcache:
	mkdir -p $(JARCACHE)
	aws s3 sync $(S3_JAR_CACHE) $(JARCACHE)

install: 
	GRADLE_OPTS="-Dmaven.repo.local=m2/repository" bash gradlew Jar

rpm: clean sync_jarcache install  
	mkdir -p $(RPMDIR)/SOURCES
	mkdir -p $(RPMDIR)/SRPMS
	mkdir -p $(RPMDIR)/RPMS
	mkdir -p $(RPMDIR)/BUILD
	mkdir -p $(RPMDIR)/BUILDROOT
	cp build/libs/zookeeper-authorizers.jar $(RPMDIR)/BUILD/
	rpmbuild -bb                                                     \
		-D "_topdir $(RPMDIR)"                                       \
		-D "_version $(REPO_VER)"                             \
		-D "_release $(REPO_REL)"                             \
		zookeeper-authorizers.spec

install_rpm: rpm
	[ ! -z $(rpm_install_dir) ] || echo must run make rpm_install_dir=...
	mkdir -p $(rpm_install_dir)
	rsync -r $(RPMDIR)/RPMS $(rpm_install_dir)
	rsync -r $(RPMDIR)/SRPMS $(rpm_install_dir)
