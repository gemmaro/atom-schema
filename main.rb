# Script to download and extract RELAX NG schema of Atom Syndication Format.
# Copyright (C) 2025  gemmaro

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# References:
# - https://datatracker.ietf.org/doc/rfc4287/
# - https://www.rfc-editor.org/rfc/rfc4287.txt

require "net/http"
require "optparse"

SOURCE_PATH = "rfc4287.txt"

def download
  Net::HTTP.start("www.rfc-editor.org", use_ssl: true) do |http|
    File.write(SOURCE_PATH, http.get("/rfc/rfc4287.txt").body)
  end
end

def extract
  license_begin = 'Full Copyright Statement'
  license_end = 'Intellectual Property'
  schema = +""
  license = +""
  File.open(SOURCE_PATH) do |file|
    file.each_line do |line|
      schema << line if line.include?('# -*- rnc -*-') .. line.include?('# EOF')
    end

    file.rewind
    file.each_line do |line|
      license << line if line.include?(license_begin) ... line.include?(license_end)
    end
  end

  header = /Nottingham & Sayre          Standards Track                    \[Page \d+\]\n/
  footer = /RFC 4287                      Atom Format                  December 2005\n/
  schema.gsub!(/\n\n\n#{ header }\n#{ footer }\n/, "")
  unindent(schema)

  license.gsub!("#{license_begin}\n\n", "")
  license.gsub!("\n#{license_end}\n", "")
  unindent(license)

  schema.sub!(/(?<=Atom Format Specification Version 11\n)/,
              +"\n" << license.gsub(/^/, "# "))
  File.write("atom.rnc", schema)
end

def unindent(str)
  str.gsub!(/^   /, "")
end

parser = OptionParser.new

parser.on("-d", "download RFC document") do
  download
  exit
end

parser.on("-e", "extract RELAX NG compact schema") do
  extract
  exit
end

parser.parse!

$stderr.puts parser
exit 1
