component "libxml2" do |pkg, settings, platform|
  pkg.version '2.10.3'
  pkg.sha256sum '3f9fb74bb02049f3454892c88d3e57a23e30a88a7d444a80064625af2f543898'
  pkg.url "https://github.com/GNOME/libxml2/archive/refs/tags/v2.10.3.tar.gz"
  pkg.mirror "#{settings[:buildsources_url]}/libxml2-#{pkg.get_version}.tar.gz"

  # Newer versions of libxml2 either ship as tar.xz or do not ship with a configure file
  # and require a newer version of GNU Autotools to generate. This causes problems with
  # the older and esoteric (AIX, Solaris) platforms that we support.
  # So we generate a configure file manually, compress as tar.gz, and host internally.

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
  elsif platform.is_solaris?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:#{settings[:bindir]}"
    pkg.environment "CFLAGS", "#{settings[:cflags]} -std=c99"
    pkg.environment "LDFLAGS", settings[:ldflags]
  elsif platform.is_macos?
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
    if platform.is_cross_compiled?
      pkg.environment 'CC', 'clang -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CC', 'clang -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end
  else
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  end

  pkg.build_requires "runtime-#{settings[:runtime_project]}"

  pkg.configure do
    ["./configure --prefix=#{settings[:prefix]} --without-python #{settings[:host]}"]
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
