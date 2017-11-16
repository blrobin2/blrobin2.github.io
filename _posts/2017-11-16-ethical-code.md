---
layout: post
title: "Ethical Code"
excerpt: "How we choose to communicate informs who we care about"
category: programming
---

Yesterday, I discussed the ethical web: that is, how we choose to communicate on the web can unintentionally limit who can consume it. Today, I want to extend that idea to how we write code.

The programming community has come to a consensus that code should be written in English. This has extended to the tools and platforms available to programmers. Some people believe this to be a "good thing", especially if the programmer themself speaks English &mdash; a well-formed English text is more accessbile than a poorly translated Polish text, as the well-formed English text is more ready to be translated into a preferred language by a native speaker of that language.

I believe this is true, to an extent. But I also believe that this idea leads to a pretend meritocracy where those who write and understand English better have greater access to resources than those who do not.

As important as this issue is, I don't know of a good solution to this problem. The expectation continues to be that if you want to learn to program and to use the hottest tools, you need to learn English.

What can I do, then, as a single programmer in such a system? One thing, both easy and impossibly difficult, is writer clearer code that is easier for my non-native English team members to comprehend. What does that look like?

Here's some ideas:
* Don't use abbreviations, especially those that can be ambiguous when put in a search engine.
* Wrap complex processes in functions whose names clearly convey what they do.
* Break up multifaceted bits of code into smaller, more easily digestible segments.
* Document classes, methods, and unclear choices in code.
* Don't use clever names or cultural references in code and documentation.
* Don't use overly complex terms unless you intend to explain their usage.
* Cleanly format code so that each line requires the least amount of mental processing to understand in the context of the whole.
* Rely on well-known conventions and patterns over specific implementation choices unless required by domain.
* Remove dead code and comments so that people have less code to read through to understand the system.
* And plenty more that I'm certain my own bias is preventing me from recognizing.

If you're at all familiar with [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882), these ideas might sound familiar. It turns out that clean code is not only a "good practice", but can actually help non-native English speakers better understand and work with your code.

You may not have any non-native English team members. This is becoming less common as programming jobs are becoming outsourced and as more non-native English speakers are applying for programming jobs in America. But you may have women or people of color on your team. You may have people with learning disabilities or information processing disorders. The concept is the same: communication patterns matter. How you choose to communicate can be limiting to people outside of your immediate culture, whether you mean it to or not.

As an aside, if your team finds it difficult to hire or keep anyone other than white men on your team; if you believe that employees should meet certain uncertain cultural expectations:

* audit your hiring process
* audit your company's culture
* audit the training material you provide
* audit your product's code using the criteria above
* observe the way your employees talk about sex and race, especially when they think no one is listening

I've barely scratched the surface of ethics in coding. This is the facet I was thinking about today (thanks to [Jenn Schiffer](https://twitter.com/jennschiffer) for her work to get this conversation going. Specifically, [this tweet got me thinking](https://twitter.com/jennschiffer/status/930526491011637249)).

Resources:
* [ACM Code of Ethics and Professional Conduct](https://www.acm.org/about-acm/acm-code-of-ethics-and-professional-conduct)
* [IEEE Code of Ethics](https://www.ieee.org/about/corporate/governance/p7-8.html)
* [Programming ethics - Wikipedia](https://en.wikipedia.org/wiki/Programming_ethics)