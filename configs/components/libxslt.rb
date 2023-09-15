component "libxslt" do |pkg, settings, platform|
  pkg.version '1.1.37'
  pkg.sha256sum 'b6f96869b8c42e8257b19d633d31e38cf12ff770829352a9dd109795ffc78bf2'
  pkg.url "https://gitlab.gnome.org/GNOME/libxslt/-/archive/v#{pkg.get_version}/libxslt-v#{pkg.get_version}.tar.gz"
  pkg.mirror "#{settings[:buildsources_url]}/libxslt-#{pkg.get_version}.tar.gz"

  # Newer versions of libxslt either ship as tar.xz or do not ship with a configure file
  # and require a newer version of GNU Autotools to generate. This causes problems with
  # the older and esoteric (AIX, Solaris) platforms that we support.
  # So we generate a configure file manually, compress as tar.gz, and host internally.

  pkg.build_requires "libxml2"

  if platform.is_aix?
    if platform.name == 'aix-7.1-ppc'
      pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH)"
    else
      pkg.environment "PATH", "/opt/freeware/bin:$(PATH)"
    end
  elsif platform.is_cross_compiled_linux?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):#{settings[:bindir]}"
    pkg.environment "CFLAGS", settings[:cflags]
    pkg.environment "LDFLAGS", settings[:ldflags]

    # libxslt is picky about manually specifying the build host
    build = "--build x86_64-linux-gnu"
    # don't depend on libgcrypto
    disable_crypto = "--without-crypto"
  elsif platform.is_solaris?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:#{settings[:bindir]}"
    pkg.environment "CFLAGS", settings[:cflags]
    pkg.environment "LDFLAGS", settings[:ldflags]
  elsif platform.is_macos?
    if platform.is_cross_compiled?
      pkg.environment 'CC', 'clang -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CC', 'clang -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  else
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  end

  pkg.configure do
    [ 
      "cp /tmp/configure .",
      "./configure --without-python --prefix=#{settings[:prefix]} --docdir=/tmp --with-libxml-prefix=#{settings[:prefix]} #{settings[:host]} #{disable_crypto} #{build}"
    ]
  end

  pkg.build do
    ["#{platform[:make]} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"]
  end

  pkg.install do
    [
      "#{platform[:make]} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install",
      "rm -rf #{settings[:datadir]}/gtk-doc",
      "rm -rf #{settings[:datadir]}/doc/#{pkg.get_name}*"
    ]
  end

end
