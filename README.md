# Get-That-Course

The University of Manitoba doesn't have a wait list feature for students trying to get into courses. This results in the major hassle of constantly checking and refreshing the webpage to see if a spot has opened. Instead, I wrote a program that does this for you, and simply emails you when a spot opens up. Students loved this, and it helped several people get into courses with ease.

The program consists of a web scraper written in Ruby. This would log into the web portal with my account credential and search for all courses. This data would be dumped into a database every 15 minutes or so. Then on the front end, people would enter their email address and the courses they were looking to get into. Every few minutes this front end program would search through the database looking for a match, and send off an email when one was found.

Here are screenshots:

<img src="https://github.com/michaelnthiessen/Get-That-Course/blob/master/screen1.png">
<img src="https://github.com/michaelnthiessen/Get-That-Course/blob/master/screen2.png">
