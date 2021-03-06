---
layout: post
title: "Stacey CMS: Part 1"
excerpt: "I introduce my intentions with this site, and begin digging around my chosen CMS, Stacey."
category: web

---
Okay. I've been trying to get this site up and going for YEARS. If you've been here before, you've been baraded by fake content and several stylistic shifts.

So, I'm saying now... forget the style. It's getting in the way. I'm starting barebones on a <abbr title="Content Management System">CMS</abbr> called Stacey.

I know, like, nothing about Stacey. And I imagine you don't either. So I've decided to do a short series of articles on Stacey. As I learn more about it, I'll use that to update the site, and then write an article about what I did. Hence, we all learn... TOGETHER! *Rainbows.*

Here's what I've learned so far about it:

It's a CMS, which means that I can set up templates for how each page will look and then write content new content using those templates. It's a way of keeping things <abbr title="Don't Repeat Yourself">DRY</abbr>, as the community calls it. So, rather than writing out the entire structure of each new page, like you would do on a static <abrr title="HyperText Markup Language">HTML</abbr> page, all I write is the content.

And dude. It doesn't get more basic than this. 

Right now, I have a .txt file open that is named after the template I want to use. Since I'm working off of the sample project that came with the install, the template is called Project. The title of the article is denoted by "title: Stacey CMS", followed by a -. Then the "date: 2013, May-". Then "content: this article". No HTML. No markup of any sort. I've just been writing paragrahps. EDIT: I've written some [PHP Markdown][php-markdown] for the links, titles and abbreviations, because that's how Stacey does it.

At this stage, there's also some filler images below, which I'm going to keep as an "example." All that's in this folder are four images: "01.jpg", "02.jpg", etc. They show up in the order they are numbered in the little slideshow below, I guess due to something in the template (we'll get there).

This is in a folder called "1.stacy-cms-01", which is in a folder called "4.articles". Why 4? Because it's the most recently added page. And, because it's the most recently added page, it shows up at the top. That's why, when I write my next article, and call it... I don't know, "Stacey CMS Part Deux" or "Stacey CMS: Electric Boogaloo", I'll put it in a folder called "2.stacey-cms-02", and it will show up on top of this one. In other words, it reverse orders it so that you can keep updating without having to worry about ordering.

### So, how do you get started? 

Easy. Go to [Stacey's Homepage][stacey], which also runs on stacey, click the installation, follow their super easy instructions. All I did was copy the folders onto the server where my site is located. (I do not recommend doing this. Set up a local server using [XAMPP for Windows][xampp] or [MAMP for Mac][mamp]. That way, you can edit everything to your heart's content and then push it live without potentially flashing a crummy looking base site). I renamed the htaccess to .htacess so that I could have clean URLs. And I basically went through folders, looking for where generic info was input, and renamed it to me.

For example, in the content folder is a file called "_shared.txt", which has some variables defined for the template, like "name", "email address", and so on. Then, I went through the rest of the content folders and looked for references to generic content and lorem ipsum, and started replacing it with real content.

Like this article! That I wrote!

If you want, you can go into the public/docs/css folder, and create some styles to make the page look... not so bare. Go as crazy or as simple as you want. This is your project, so have fun with it. I know I would increase some of these fonts sizes so that people without binocular eyes can read the text.

Want to follow along, but don't know ANYTHING about HTML or <abbr="Cascading Style Sheet">CSS</abbr>? Try [Tuts+'s Free 30 Day Course to Learn HTML and CSS][tutsplus]. Even after learning HTML and CSS on my own, I found this course crucial to getting up to date with the most recent versions, HTML5 and CSS3. It even includes a section on building a full site towards the end. So, even though Stacey is built on PHP, you don't have to know any of it to get started.

In the next article, I'll write about customzing templates (so that I can remove the dummy image slider down below), building my own, and how to organize a project on Stacey.

<del>You can also follow this project on [github][staceybuild].</del> EDIT: The site has since moved to Jekyll, but the previous version of the site is being kept online for those who wish to look at the source.

See you next time!

[php-markdown]: http://michelf.ca/projects/php-markdown/
[stacey]: http://staceyapp.com
[xampp]: http://www.apachefriends.org/en/xampp.html
[mamp]: http://www.mamp.info/en/index.html
[tutsplus]: http://learncss.tutsplus.com/
[staceybuild]: https://github.com/blrobin2/personalsite-staceybuild
