class FirefoxDependency < Requirement
  fatal true
  default_formula "xulrunner" if MacOS.version < :yosemite

  def self.firefox_installation
    paths = ["~/Applications/FirefoxNightly.app", "~/Applications/Firefox.app",
             "/Applications/FirefoxNightly.app", "/Applications/Firefox.app"]
    paths.find { |p| File.exist? File.expand_path(p) }
  end

  satisfy { Formula["xulrunner"].installed? || FirefoxDependency.firefox_installation }

  def message
    "Firefox or xulrunner must be available."
  end
end

class Slimerjs < Formula
  homepage "http://www.slimerjs.org"
  url "http://download.slimerjs.org/releases/0.9.5/slimerjs-0.9.5-mac.tar.bz2"
  sha256 "4333ae1c7898789c71b65ba5767cd1781290cdad36cb64d58ef289933482c81b"
  head "https://github.com/laurentj/slimerjs.git"

  bottle do
    cellar :any
    sha1 "77b0703ee315c809ea9a1307b88f0a622affeedc" => :mavericks
    sha1 "aa5654afdd8d2dc049878d2898b9fb7fa33911ab" => :mountain_lion
  end

  option "without-xulrunner", "Build with xulrunner"

  # Min supported OS X version by Firefox & xulrunner is 10.6
  depends_on :macos => :leopard
  depends_on FirefoxDependency

  def install
    cd "src" do
      system "zip", "-r", "omni.ja", "chrome/", "components/", "modules/",
                    "defaults/", "chrome.manifest", "-x@package_exclude.lst"
    end unless build.stable?
    libexec.install %w[application.ini omni.ja slimerjs slimerjs.py]
    bin.install_symlink libexec/"slimerjs"
  end

  def caveats
    s = ""

    if (firefox_installation = FirefoxDependency.firefox_installation)
      s += <<-EOS.undent
        You MUST provide an installation of Mozilla Firefox and set
        the environment variable SLIMERJSLAUNCHER pointing to it, e.g.:

        export SLIMERJSLAUNCHER=#{firefox_installation}/Contents/MacOS/firefox
        EOS
    end
    s += <<-EOS.undent

      Note: If you use SlimerJS with an unstable version of Mozilla Firefox/XULRunner (>36.*)
      you may have to change the [Gecko]MaxVersion in #{libexec}/application.ini
    EOS

    s
  end

  test do
    if build.with?("xulrunner")
      system "#{bin}/slimerjs", "-v"
      system "#{bin}/slimerjs", "loadspeed.js", "https://www.google.com"
    end
  end
end
