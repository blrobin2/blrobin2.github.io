require 'csv'

CSV.foreach("reviews.csv", headers: true) do |row|

  tags = row['Tags']&.split(",")&.map(&:strip)&.map(&:downcase)&.map { |s| s.gsub(" ", "-") }

  filename = row['Date'] + '-' + row['Name'].downcase.gsub(" ", "-").gsub(/[^a-z0-9\-]/, '') + '.md'
  content = File.read("./_posts/" + filename)
  modified_content = content.gsub"####### tags #######", tags ? "tags: [#{tags.join(", ")}]" : "tags: []"
  File.write("./_posts/" + filename, modified_content)

end
