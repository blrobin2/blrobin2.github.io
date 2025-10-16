---
layout: default
title: Search Results
permalink: /search
---

<ul id="search-results" class="search-results"></ul>

<script>
    window.store = {
        {% for post in site.posts %}
            "{{ post.url | slugify }}" : {
                "title": "{{ post.title | xml_escape }}",
                "date": "{{ post.date | date_to_string }}",
                "category": "{{ post.category | xml_escape }}",
                "content": {{ post.content | strip_html | strip_newlines | jsonify }},
                "url": "{{ post.url | xml_escape }}"
            }
            {% unless forloop.last %},{% endunless %}
        {% endfor %}
    };
</script>
<script src="https://unpkg.com/lunr/lunr.js"></script>
<script src="/js/search.js"></script>
