# Homebrew Cask for Zaryad
cask "zaryad" do
  version "0.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/OWNER/zaryad/releases/download/v#{version}/Zaryad-#{version}-universal.dmg"
  name "Zaryad"
  desc "macOS battery and charger monitor"
  homepage "https://github.com/OWNER/zaryad"

  depends_on macos: ">= :sonoma"

  app "Zaryad.app"

  zap trash: [
    "~/Library/Preferences/com.worldproject.zaryad.plist",
    "~/Library/Application Support/com.worldproject.zaryad",
  ]
end
