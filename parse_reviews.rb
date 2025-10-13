require 'csv'

CSV.foreach("reviews.csv", headers: true) do |row|

  tags = row['Tags']&.split(",")&.map(&:strip)
  mst3k = tags&.include?("mst3k")
  rifftrax = tags&.include?("rifftrax")

  rating = row['Rating']&.strip
  if rating&.length == 1
    rating += ".0"
  end

  header = <<~HEADER
---
layout: review
title: "#{row['Name']} (#{row['Year']})"
excerpt: "My review of #{row['Name']} (#{row['Year']})"
rating: "#{rating}"
letterboxd_url: #{row['Letterboxd URI']}
mst3k: #{mst3k}
rifftrax: #{rifftrax}
category: movie_review

---
  HEADER

  filename = row['Date'] + '-' + row['Name'].downcase.gsub(" ", "-").gsub(/[^a-z0-9\-]/, '') + '.md'

  File.open("_posts/" + filename, "w") do |file|
    file.write(header)
    file.write("\n")
    file.write(row['Review'])
  end
end
