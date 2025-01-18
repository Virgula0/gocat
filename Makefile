check_root = \
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "\033[0;31mThis target requires root privileges. Please run as root.\033[0m\n"; \
		exit 1; \
	fi

install-hashcat:
	$(call check_root)
	{ \
		cd externals/hashcat; \
		make install SHARED=1 ENABLE_BRAIN=0; \
		cp deps/LZMA-SDK/C/LzmaDec.h /usr/local/include/hashcat/; \
		cp deps/LZMA-SDK/C/7zTypes.h /usr/local/include/hashcat/; \
		cp deps/LZMA-SDK/C/Lzma2Dec.h /usr/local/include/hashcat/; \
		cp -r OpenCL/inc_types.h /usr/local/include/hashcat/; \
		cp -r deps/zlib/contrib /usr/local/include/hashcat; \
		# Important needed symlinks to the hashcat library  \
		ln -s /usr/local/lib/libhashcat.so.6.1.1 /usr/local/lib/libhashcat.so; \
		ln -s /usr/local/lib/libhashcat.so.6.1.1 /usr/lib/libhashcat.so.6.1.1;  \
	}
.PHONY: install

uninstall-hashcat:
	$(call check_root)
	cd externals/hashcat && \
	make uninstall
	rm -f /usr/local/lib/libhashcat.so
	rm -f /usr/lib/libhashcat.so.6.1.1
.PHONY: uninstall

set-user-permissions:
	$(call check_root)
	chown -R $(USER):$(USER) /usr/local/share/hashcat 
.PHONY: set-permissions

checkout-subrepo:
	@if [ "$$(id -u)" -ne 0 ]; then \
		git submodule update; \
		git pull --recurse-submodules; \
	fi
	cd externals/hashcat && \
	git reset --hard && \
	git checkout v6.1.1
.PHONY: checkout-subrepo

# Symbolic links needed for running tests. HashCat must have installed via make install
links:
	@{ \
		if [ ! -e "OpenCL" ]; then \
			ln -s /usr/local/share/hashcat/OpenCL OpenCL; \
			echo "Created symbolic link for OpenCL"; \
		fi; \
		if [ ! -e "hashcat.hctune" ]; then \
			ln -s /usr/local/share/hashcat/hashcat.hctune hashcat.hctune; \
		fi; \
		if [ ! -e "modules" ]; then \
			ln -s /usr/local/share/hashcat/modules modules; \
		fi; \
	}
.PHONY: links

clean:
	rm -f *.test
	rm -f *.dictstat*
	rm -f *.hctune
	rm -f *.log
	rm -f *.pid
	rm -rf modules
	rm -rf OpenCL
	rm -rf kernels
.PHONY: clean

test-only:
	@rm -rf hashcat.pid
	@go test -c ./...
	@./*.test
.PHONY: test

test: links test-only clean
uninstall: checkout-subrepo uninstall-hashcat
install: checkout-subrepo install-hashcat
