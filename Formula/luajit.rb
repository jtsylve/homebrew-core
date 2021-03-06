class Luajit < Formula
  desc "Just-In-Time Compiler (JIT) for the Lua programming language"
  homepage "http://luajit.org/luajit.html"
  url "http://luajit.org/download/LuaJIT-2.0.4.tar.gz"
  sha256 "620fa4eb12375021bef6e4f237cbd2dd5d49e56beb414bee052c746beef1807d"
  revision 1

  head "http://luajit.org/git/luajit-2.0.git"

  bottle do
    sha256 "38b21090f297f25d5ff011aebc4dd1b91f1ca8660c9cdbcb61abc9d42c63dd58" => :el_capitan
    sha256 "56302fd3162c220a4ebdc64481e07665fa76035d0b0fab29eb9375ccb505fc28" => :yosemite
    sha256 "cdef95c2178de6852d295a596c85f01733e67e54b1e026021b136586a185ad0d" => :mavericks
  end

  devel do
    url "http://luajit.org/download/LuaJIT-2.1.0-beta2.tar.gz"
    sha256 "713924ca034b9d99c84a0b7b701794c359ffb54f8e3aa2b84fad52d98384cf47"

    # https://github.com/LuaJIT/LuaJIT/issues/180
    patch do
      url "https://github.com/LuaJIT/LuaJIT/commit/5837c2a2fb1ba6651.diff"
      sha256 "7b5d233fc3a95437bd1c8459ad35bba63825655f47951b6dba1d053df7f98587"
    end
  end

  deprecated_option "enable-debug" => "with-debug"

  option "with-debug", "Build with debugging symbols"
  option "with-52compat", "Build with additional Lua 5.2 compatibility"

  def install
    # 1 - Override the hardcoded gcc.
    # 2 - Remove the "-march=i686" so we can set the march in cflags.
    # Both changes should persist and were discussed upstream.
    inreplace "src/Makefile" do |f|
      f.change_make_var! "CC", ENV.cc
      f.change_make_var! "CCOPT_x86", ""
    end

    ENV.O2 # Respect the developer's choice.

    args = %W[PREFIX=#{prefix}]
    args << "XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT" if build.with? "52compat"

    # This doesn't yet work under superenv because it removes "-g"
    args << "CCDEBUG=-g" if build.with? "debug"

    # The development branch of LuaJIT normally does not install "luajit".
    args << "INSTALL_TNAME=luajit" if build.devel?

    system "make", "amalg", *args
    system "make", "install", *args

    # LuaJIT doesn't automatically symlink unversioned libraries:
    # https://github.com/Homebrew/homebrew/issues/45854.
    lib.install_symlink lib/"libluajit-5.1.dylib" => "libluajit.dylib"
    lib.install_symlink lib/"libluajit-5.1.a" => "libluajit.a"

    # Having an empty Lua dir in lib/share can mess with other Homebrew Luas.
    %W[ #{lib}/lua #{share}/lua ].each { |d| rm_rf d }
  end

  test do
    system "#{bin}/luajit", "-e", <<-EOS.undent
      local ffi = require("ffi")
      ffi.cdef("int printf(const char *fmt, ...);")
      ffi.C.printf("Hello %s!\\n", "#{ENV["USER"]}")
    EOS
  end
end
