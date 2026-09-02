"""Wipes all course-related data and replaces it with a large, standard demo
catalog: 30 courses across a dozen categories, each with several lessons,
and a quiz on every lesson.

Leaves users, auth tokens, and feedback untouched. Reuses whatever files are
already sitting in media/{videos,pdfs} for lesson attachments, and copies each
course's hand-picked cover art from mobile/assets/image/ into media/images/ —
no URLs are invented.

Each lesson gets a two-question quiz:
  1. A "what did this lesson cover?" question, generated from the lesson's
     own topic phrase vs. its sibling lessons' topic phrases in the same
     course (so distractors are always real, on-topic content from the
     same course, never generic noise).
  2. A hand-written, category-level conceptual question (cycled from a
     small per-category bank), so every quiz tests real domain knowledge
     too, not just lesson recall.

Run from backend/, with the venv active:
    python seed_courses.py
"""

import shutil
from pathlib import Path

from sqlalchemy import text

from app.db.session import SessionLocal
from app.models.course import Course, Lesson
from app.models.quiz import Choice, Question, Quiz
from app.models.user import User, UserRole

# Cover art lives in the mobile app's own asset bundle (one hand-picked image
# per course, added there for design purposes) — reused here as the course's
# real cover_image_url instead of a generic stand-in, so admin panel, mobile
# app, and any future web client all see the same purpose-made cover.
MOBILE_ASSETS_IMAGE_DIR = Path(__file__).resolve().parent.parent / "mobile" / "assets" / "image"
MEDIA_IMAGES_DIR = Path("media") / "images"

# course title -> (source filename in mobile/assets/image/, clean slug for
# the copy stored under media/images/)
COVER_IMAGES: dict[str, tuple[str, str]] = {
    "Introduction to Python Programming": ("intro_python_pro.jpg", "intro_python_programming"),
    "Advanced JavaScript & Async Patterns": ("avanced_javascript.jpg", "advanced_javascript_async"),
    "Java Programming Fundamentals": ("java_pro_fund.jpg", "java_programming_fundamentals"),
    "C++ for Beginners": ("c++_begnners.jpg", "cpp_for_beginners"),
    "Go Programming Essentials": ("go_programming_ess.jpg", "go_programming_essentials"),
    "SQL for Data Analysis": ("sql_data_analysis.jpg", "sql_for_data_analysis"),
    "Web Development Fundamentals": ("web_dev_fund.jpg", "web_development_fundamentals"),
    "React.js Essentials": ("react_ess.jpg", "reactjs_essentials"),
    "Node.js Backend Development": ("node_backend.jpg", "nodejs_backend_development"),
    "Responsive Web Design": ("responsive_web_design.jpg", "responsive_web_design"),
    "Data Science Basics": ("data_science_basic.jpg", "data_science_basics"),
    "Machine Learning Foundations": ("machine_learning_found.jpg", "machine_learning_foundations"),
    "Data Visualization with Python": ("data_visualization_python.jpg", "data_visualization_python"),
    "Excel for Data Analysis": ("excel_data_analysis.jpg", "excel_for_data_analysis"),
    "UI/UX Design Principles": ("ui_design_principles.jpg", "ui_ux_design_principles"),
    "Graphic Design Fundamentals": ("graphic_design_fund.png", "graphic_design_fundamentals"),
    "Figma for Product Design": ("figma_product.jpg", "figma_for_product_design"),
    "Digital Marketing Essentials": ("digital_marketing.jpg", "digital_marketing_essentials"),
    "Social Media Marketing Strategy": ("social_media_marketing.jpg", "social_media_marketing_strategy"),
    "Search Engine Optimization (SEO)": ("search_engine_optimization.jpg", "search_engine_optimization"),
    "Project Management Fundamentals": ("project_management_fund.jpg", "project_management_fundamentals"),
    "Entrepreneurship 101": ("entrepreneurship.jpg", "entrepreneurship_101"),
    "Public Speaking and Presentation Skills": ("public_speaking.jpg", "public_speaking_presentation"),
    "Personal Finance Basics": ("personal_finance_basic.jpg", "personal_finance_basics"),
    "AWS Cloud Fundamentals": ("aws_cloud_fund.jpg", "aws_cloud_fundamentals"),
    "Docker and Containers": ("docker_container.jpg", "docker_and_containers"),
    "Introduction to Cybersecurity": ("intro_cybersecurity.jpg", "intro_to_cybersecurity"),
    "Flutter Mobile App Development": ("flutter_mobile_app_dev.jpg", "flutter_mobile_app_development"),
    "Android Development with Kotlin": ("android_dev_kotlin.jpg", "android_development_kotlin"),
    "Photography Fundamentals": ("photography_fund.jpg", "photography_fundamentals"),
}


def cover_image_url_for(course_title: str) -> str:
    filename, slug = COVER_IMAGES[course_title]
    src = MOBILE_ASSETS_IMAGE_DIR / filename
    if not src.exists():
        raise SystemExit(f"Missing cover image asset: {src}")
    stored_name = f"seedcover_{slug}{src.suffix.lower()}"
    MEDIA_IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, MEDIA_IMAGES_DIR / stored_name)
    return f"/media/images/{stored_name}"


VIDEOS = [
    "/media/videos/76eadef4a7ae43ba891be5e35ee2fb4d.mp4",
    "/media/videos/dd423566b77246f08a8cda253edf7256.mp4",
    "/media/videos/f0826aa2926d4a24a973525fbc619055.mp4",
]
PDFS = [
    "/media/pdfs/112588941ff14edc94c094ecb7eefd84.pdf",
    "/media/pdfs/46db623025d04d2c82b69e11e33c362c.pdf",
    "/media/pdfs/5888310e424d4f85baf5b649e4e3a209.pdf",
    "/media/pdfs/d4b7574cf5354ea5b045a652b050e228.pdf",
]

# One "what does this actually mean" conceptual question per category,
# cycled across that category's lessons as each quiz's second question.
CATEGORY_QUESTIONS: dict[str, list[tuple[str, str, list[str]]]] = {
    "Programming": [
        (
            "What is a variable used for in programming?",
            "Storing a value that can be used or changed later",
            ["Deleting files from disk", "Compiling the operating system", "Connecting to the internet"],
        ),
        (
            "What does \"debugging\" mean?",
            "Finding and fixing errors in code",
            ["Writing documentation", "Deploying to production", "Designing a logo"],
        ),
    ],
    "Web Development": [
        (
            "What does HTML provide for a web page?",
            "Structure and content",
            ["Only colors and fonts", "Database storage", "Server security"],
        ),
        (
            "What is the purpose of CSS?",
            "Styling and layout of a web page",
            ["Storing user data", "Running server-side logic", "Sending emails"],
        ),
    ],
    "Data Science": [
        (
            "What is the main goal of data cleaning?",
            "Making data accurate and consistent before analysis",
            ["Making charts more colorful", "Deleting all the data", "Increasing file size"],
        ),
        (
            "Why do data scientists use visualizations?",
            "To communicate patterns and insights clearly",
            ["To slow down analysis", "To hide results", "To replace all the data"],
        ),
    ],
    "Design": [
        (
            "What is the goal of UX design?",
            "Making products easy and pleasant for people to use",
            ["Making the code run faster", "Reducing server costs", "Writing marketing copy"],
        ),
        (
            "Why is visual hierarchy important?",
            "It guides attention to what matters most",
            ["It hides important information", "It's only about color trends", "It replaces content"],
        ),
    ],
    "Marketing": [
        (
            "What is the purpose of SEO?",
            "Helping a website rank higher in search results",
            ["Increasing server speed", "Designing logos", "Writing legal contracts"],
        ),
        (
            "Why do marketers track metrics?",
            "To measure what's working and improve strategy",
            ["To slow down campaigns", "Because it's legally required", "To reduce audience size"],
        ),
    ],
    "Business": [
        (
            "Why is planning important in project management?",
            "It helps teams meet goals on time and on budget",
            ["It guarantees no problems will happen", "It's optional busywork", "It replaces teamwork"],
        ),
        (
            "What is a core skill in public speaking?",
            "Clearly communicating ideas to an audience",
            ["Speaking as fast as possible", "Avoiding eye contact", "Reading only from a script"],
        ),
    ],
    "Cloud & DevOps": [
        (
            "What is a key benefit of cloud computing?",
            "On-demand access to computing resources without owning hardware",
            ["It removes the need for the internet", "It's always free", "It replaces programming"],
        ),
        (
            "What is a container used for?",
            "Packaging an app with everything it needs to run consistently",
            ["Storing physical files only", "Replacing databases", "Designing user interfaces"],
        ),
    ],
    "Cybersecurity": [
        (
            "What is the purpose of a strong, unique password?",
            "Making it harder for attackers to gain unauthorized access",
            ["Making login slower for everyone", "Improving internet speed", "Replacing antivirus software"],
        ),
        (
            "What is phishing?",
            "A scam that tricks people into revealing sensitive information",
            ["A method of encrypting files", "A type of firewall", "A programming language"],
        ),
    ],
    "Mobile Development": [
        (
            "What is a benefit of cross-platform frameworks like Flutter?",
            "Writing one codebase that runs on multiple platforms",
            ["Making apps slower on purpose", "Only working on one device", "Replacing the need for design"],
        ),
        (
            "What is an app's UI responsible for?",
            "What the user sees and interacts with",
            ["Only backend database storage", "Server security only", "Billing and payments only"],
        ),
    ],
    "Creative": [
        (
            "What does \"exposure\" control in photography?",
            "How light or dark an image appears",
            ["The color of the lens", "The camera's brand", "The file format only"],
        ),
        (
            "Why is composition important in photography?",
            "It guides how the viewer's eye moves through the image",
            ["It only matters for black-and-white photos", "It controls battery life", "It replaces lighting"],
        ),
    ],
}

# (title, category, level, [(lesson_title, topic_phrase), ...])
COURSES: list[tuple[str, str, str, list[tuple[str, str]]]] = [
    (
        "Introduction to Python Programming",
        "Programming",
        "beginner",
        [
            ("Getting Started with Python", "installing Python, running your first script, and using variables and print()"),
            ("Control Flow: if, for, while", "making decisions and repeating actions with if/elif/else and loops"),
            ("Functions and Reusability", "defining functions with def, using parameters, and return values"),
            ("Working with Lists and Dictionaries", "storing and working with collections of data"),
        ],
    ),
    (
        "Advanced JavaScript & Async Patterns",
        "Programming",
        "advanced",
        [
            ("Closures and Scope", "how functions remember variables from their defining scope"),
            ("The Event Loop", "how JavaScript handles the call stack and asynchronous tasks"),
            ("Promises and async/await", "writing asynchronous code that reads like synchronous code"),
            ("Modules and Modern Tooling", "organizing code with ES modules and modern build tools"),
        ],
    ),
    (
        "Java Programming Fundamentals",
        "Programming",
        "beginner",
        [
            ("Java Syntax and Data Types", "variables, primitive types, and basic Java syntax"),
            ("Object-Oriented Programming in Java", "classes, objects, and encapsulation"),
            ("Control Flow and Loops", "if statements, switch, and for/while loops in Java"),
            ("Arrays and Collections", "storing groups of data with arrays and the Collections framework"),
            ("Exception Handling", "catching and handling errors safely with try/catch"),
        ],
    ),
    (
        "C++ for Beginners",
        "Programming",
        "beginner",
        [
            ("Introduction to C++", "compiling and running your first C++ program"),
            ("Variables, Types, and Operators", "core data types and arithmetic in C++"),
            ("Functions and Pointers", "writing reusable functions and understanding pointers"),
            ("Arrays and Strings", "working with fixed-size collections and text"),
            ("Object-Oriented Basics", "classes and objects in C++"),
        ],
    ),
    (
        "Go Programming Essentials",
        "Programming",
        "intermediate",
        [
            ("Go Syntax and Types", "variables, types, and Go's simple syntax"),
            ("Functions and Error Handling", "multiple return values and Go's explicit error handling"),
            ("Goroutines and Channels", "lightweight concurrency with goroutines and channels"),
            ("Structs and Interfaces", "defining custom types and behavior in Go"),
        ],
    ),
    (
        "SQL for Data Analysis",
        "Programming",
        "beginner",
        [
            ("Introduction to SQL and SELECT", "querying data from a database with SELECT statements"),
            ("Filtering and Sorting Data", "using WHERE, ORDER BY, and LIMIT to narrow results"),
            ("Joins Across Tables", "combining data from multiple tables with JOIN"),
            ("Aggregations and Grouping", "summarizing data with GROUP BY, COUNT, SUM, and AVG"),
        ],
    ),
    (
        "Web Development Fundamentals",
        "Web Development",
        "beginner",
        [
            ("HTML Structure and Semantics", "the building blocks of a web page and semantic tags"),
            ("Styling with CSS", "selectors, the box model, and flexbox layout"),
            ("JavaScript Basics", "variables, functions, and DOM manipulation"),
            ("Building a Simple Page Layout", "combining HTML, CSS, and JS into a complete page"),
        ],
    ),
    (
        "React.js Essentials",
        "Web Development",
        "intermediate",
        [
            ("Components and JSX", "building UI with reusable components and JSX syntax"),
            ("Props and State", "passing data between components and managing local state"),
            ("Handling Events and Forms", "responding to user interaction and controlled inputs"),
            ("Hooks: useState and useEffect", "managing state and side effects in function components"),
        ],
    ),
    (
        "Node.js Backend Development",
        "Web Development",
        "intermediate",
        [
            ("Introduction to Node.js", "running JavaScript on the server and the Node runtime"),
            ("Building APIs with Express", "routing and handling HTTP requests with Express"),
            ("Working with Databases", "connecting a Node app to a database"),
            ("Authentication Basics", "verifying users with tokens and sessions"),
        ],
    ),
    (
        "Responsive Web Design",
        "Web Development",
        "beginner",
        [
            ("Responsive Design Principles", "designing layouts that adapt to any screen size"),
            ("Media Queries", "applying different styles based on screen width"),
            ("Flexbox and Grid Layout", "modern CSS layout systems for responsive pages"),
            ("Mobile-First Design", "designing for small screens first, then scaling up"),
        ],
    ),
    (
        "Data Science Basics",
        "Data Science",
        "intermediate",
        [
            ("Data Analysis with pandas", "loading, filtering, and transforming data with DataFrames"),
            ("Data Cleaning and Preparation", "handling missing values and inconsistent data"),
            ("Data Visualization Fundamentals", "turning numbers into clear charts and insight"),
            ("Intro to Statistics for Data Science", "mean, median, and distributions used in analysis"),
        ],
    ),
    (
        "Machine Learning Foundations",
        "Data Science",
        "advanced",
        [
            ("What is Machine Learning?", "how machines learn patterns from data instead of explicit rules"),
            ("Supervised Learning Basics", "training models to predict outcomes from labeled data"),
            ("Model Evaluation", "measuring accuracy and avoiding overfitting"),
            ("Unsupervised Learning", "finding patterns in data without labels, like clustering"),
        ],
    ),
    (
        "Data Visualization with Python",
        "Data Science",
        "intermediate",
        [
            ("Introduction to matplotlib", "creating basic charts with Python's core plotting library"),
            ("Choosing the Right Chart", "matching chart types to the story your data tells"),
            ("Customizing Visuals", "labels, colors, and annotations that make charts clear"),
            ("Building Dashboards", "combining multiple charts into one view"),
        ],
    ),
    (
        "Excel for Data Analysis",
        "Data Science",
        "beginner",
        [
            ("Excel Basics and Formulas", "cells, formulas, and basic functions like SUM and AVERAGE"),
            ("Sorting and Filtering Data", "organizing and narrowing down large spreadsheets"),
            ("PivotTables", "summarizing large datasets quickly with PivotTables"),
            ("Charts in Excel", "turning spreadsheet data into visual charts"),
        ],
    ),
    (
        "UI/UX Design Principles",
        "Design",
        "beginner",
        [
            ("Foundations of User-Centered Design", "designing around real user needs instead of assumptions"),
            ("Visual Hierarchy and Layout", "using size, color, and spacing to guide the eye"),
            ("Wireframing and Prototyping", "sketching layouts and testing ideas before building"),
            ("Usability Testing Basics", "observing real users to find friction in a design"),
        ],
    ),
    (
        "Graphic Design Fundamentals",
        "Design",
        "beginner",
        [
            ("Principles of Design", "balance, contrast, alignment, and repetition"),
            ("Color Theory", "how color combinations affect mood and readability"),
            ("Typography Basics", "choosing and pairing fonts effectively"),
            ("Working with Layout and Grids", "organizing visual elements with a grid system"),
        ],
    ),
    (
        "Figma for Product Design",
        "Design",
        "intermediate",
        [
            ("Figma Interface Basics", "frames, layers, and the Figma workspace"),
            ("Components and Variants", "building reusable, consistent UI elements"),
            ("Auto Layout", "creating flexible layouts that resize automatically"),
            ("Prototyping and Handoff", "linking screens together and preparing files for developers"),
        ],
    ),
    (
        "Digital Marketing Essentials",
        "Marketing",
        "beginner",
        [
            ("Introduction to SEO", "how search engines rank pages and on-page basics"),
            ("Social Media Strategy", "planning content and measuring engagement across platforms"),
            ("Email Marketing Basics", "building lists and writing emails people actually open"),
            ("Marketing Analytics 101", "tracking clicks, conversions, and campaign performance"),
        ],
    ),
    (
        "Social Media Marketing Strategy",
        "Marketing",
        "beginner",
        [
            ("Choosing the Right Platforms", "matching platforms to where your audience actually is"),
            ("Content Planning and Calendars", "planning consistent, on-brand content ahead of time"),
            ("Growing an Engaged Audience", "building a community instead of just followers"),
            ("Measuring Social Media ROI", "connecting social activity to real business results"),
        ],
    ),
    (
        "Search Engine Optimization (SEO)",
        "Marketing",
        "intermediate",
        [
            ("Keyword Research", "finding the terms your audience actually searches for"),
            ("On-Page SEO", "optimizing titles, headings, and content for search engines"),
            ("Technical SEO Basics", "site speed, mobile-friendliness, and crawlability"),
            ("Link Building Fundamentals", "earning credibility through quality backlinks"),
        ],
    ),
    (
        "Project Management Fundamentals",
        "Business",
        "beginner",
        [
            ("Project Management Basics", "scope, timeline, and budget — the project triangle"),
            ("Planning and Scheduling", "breaking work into tasks and milestones"),
            ("Managing Risk", "identifying and preparing for what could go wrong"),
            ("Agile vs. Waterfall", "comparing iterative and sequential project approaches"),
        ],
    ),
    (
        "Entrepreneurship 101",
        "Business",
        "beginner",
        [
            ("Finding a Business Idea", "spotting real problems worth solving"),
            ("Validating Your Idea", "testing demand before building the full product"),
            ("Building a Simple Business Plan", "outlining your model, market, and finances"),
            ("Raising Initial Funding", "common ways early-stage businesses get funded"),
        ],
    ),
    (
        "Public Speaking and Presentation Skills",
        "Business",
        "beginner",
        [
            ("Overcoming Stage Fright", "practical techniques to manage nerves before speaking"),
            ("Structuring a Clear Talk", "an opening, body, and closing that keep an audience engaged"),
            ("Using Visual Aids Effectively", "slides that support your message instead of distracting from it"),
            ("Engaging Your Audience", "eye contact, tone, and pacing that hold attention"),
        ],
    ),
    (
        "Personal Finance Basics",
        "Business",
        "beginner",
        [
            ("Budgeting Fundamentals", "tracking income and expenses to spend with intention"),
            ("Saving and Emergency Funds", "building a safety net for unexpected costs"),
            ("Understanding Credit", "how credit scores work and why they matter"),
            ("Intro to Investing", "the basics of growing money over time"),
        ],
    ),
    (
        "AWS Cloud Fundamentals",
        "Cloud & DevOps",
        "beginner",
        [
            ("What is Cloud Computing?", "on-demand computing resources instead of owning hardware"),
            ("Core AWS Services", "an overview of compute, storage, and networking on AWS"),
            ("Storage with S3", "storing and retrieving files reliably in the cloud"),
            ("Security and IAM Basics", "controlling who can access what in your cloud account"),
        ],
    ),
    (
        "Docker and Containers",
        "Cloud & DevOps",
        "intermediate",
        [
            ("What is a Container?", "packaging an app with everything it needs to run consistently"),
            ("Writing a Dockerfile", "defining how to build your application's image"),
            ("Working with Docker Images", "building, tagging, and running containers"),
            ("Docker Compose Basics", "running multi-container applications together"),
        ],
    ),
    (
        "Introduction to Cybersecurity",
        "Cybersecurity",
        "beginner",
        [
            ("Core Security Concepts", "confidentiality, integrity, and availability"),
            ("Common Threats and Attacks", "phishing, malware, and social engineering"),
            ("Passwords and Authentication", "why strong, unique passwords and MFA matter"),
            ("Staying Safe Online", "everyday habits that reduce your risk"),
        ],
    ),
    (
        "Flutter Mobile App Development",
        "Mobile Development",
        "intermediate",
        [
            ("Introduction to Flutter and Widgets", "building UI with Flutter's widget tree"),
            ("Layouts in Flutter", "arranging widgets with Row, Column, and Stack"),
            ("State Management Basics", "keeping UI in sync with changing data"),
            ("Navigation Between Screens", "moving between pages in a Flutter app"),
        ],
    ),
    (
        "Android Development with Kotlin",
        "Mobile Development",
        "intermediate",
        [
            ("Kotlin Language Basics", "variables, functions, and null safety in Kotlin"),
            ("Android Activities and Layouts", "screens and XML layouts in an Android app"),
            ("Handling User Input", "responding to clicks and form input"),
            ("Working with Data and Storage", "saving data locally on an Android device"),
        ],
    ),
    (
        "Photography Fundamentals",
        "Creative",
        "beginner",
        [
            ("Understanding Your Camera", "aperture, shutter speed, and ISO — the exposure triangle"),
            ("Composition Basics", "rule of thirds, leading lines, and framing"),
            ("Lighting Fundamentals", "how natural and artificial light shape a photo"),
            ("Editing Your Photos", "basic adjustments that improve a shot after capture"),
        ],
    ),
]


def recall_question(lesson_title: str, topic_phrase: str, sibling_phrases: list[str]) -> Question:
    """'What did this lesson cover?' — distractors are real topic phrases
    from sibling lessons in the same course, never generic filler."""
    wrong = sibling_phrases[:3]
    choices = [Choice(text=topic_phrase.capitalize(), is_correct=True)] + [
        Choice(text=w.capitalize(), is_correct=False) for w in wrong
    ]
    return Question(
        text=f'What does the lesson "{lesson_title}" primarily cover?',
        order_index=0,
        choices=choices,
    )


def category_question(category: str, index: int) -> Question:
    pool = CATEGORY_QUESTIONS[category]
    text_, correct, wrong = pool[index % len(pool)]
    choices = [Choice(text=correct, is_correct=True)] + [Choice(text=w, is_correct=False) for w in wrong]
    return Question(text=text_, order_index=1, choices=choices)


def build_courses(created_by: int) -> list[Course]:
    courses: list[Course] = []
    for c_idx, (title, category, level, lesson_specs) in enumerate(COURSES):
        phrases = [phrase for _, phrase in lesson_specs]
        lessons: list[Lesson] = []
        for l_idx, (lesson_title, topic_phrase) in enumerate(lesson_specs):
            siblings = [p for i, p in enumerate(phrases) if i != l_idx]
            quiz = Quiz(
                title=f"{lesson_title} Quiz",
                passing_score=70 if level != "advanced" else 75,
                questions=[
                    recall_question(lesson_title, topic_phrase, siblings),
                    category_question(category, c_idx + l_idx),
                ],
            )
            use_video = l_idx % 2 == 0
            lessons.append(
                Lesson(
                    order_index=l_idx,
                    title=lesson_title,
                    content=f"In this lesson, you'll learn about {topic_phrase}.",
                    video_url=VIDEOS[(c_idx + l_idx) % len(VIDEOS)] if use_video else None,
                    file_url=PDFS[(c_idx + l_idx) % len(PDFS)] if not use_video else None,
                    quiz=quiz,
                )
            )
        courses.append(
            Course(
                title=title,
                description=(
                    f"A {level} course covering {', '.join(p.split(' and ')[0] for p in phrases[:3])}, "
                    f"and more — {len(lessons)} lessons with a quiz on every one."
                ),
                category=category,
                level=level,
                cover_image_url=cover_image_url_for(title),
                created_by=created_by,
                lessons=lessons,
            )
        )
    return courses


def main() -> None:
    db = SessionLocal()
    try:
        admin = (
            db.query(User)
            .filter(User.role.in_([UserRole.admin, UserRole.super_admin]))
            .order_by(User.id)
            .first()
        )
        if admin is None:
            raise SystemExit("No admin/super_admin user found — create one first.")

        print(f"Using created_by = {admin.id} ({admin.email})")

        for table in (
            "quiz_attempt_answers",
            "quiz_attempts",
            "lesson_progress",
            "choices",
            "questions",
            "quizzes",
            "certificates",
            "course_reviews",
            "lessons",
            "courses",
        ):
            result = db.execute(text(f"DELETE FROM {table}"))
            print(f"  cleared {table}: {result.rowcount} rows")
        db.commit()

        for table in (
            "courses",
            "lessons",
            "quizzes",
            "questions",
            "choices",
            "certificates",
            "course_reviews",
            "quiz_attempts",
            "quiz_attempt_answers",
            "lesson_progress",
        ):
            db.execute(text(f"ALTER TABLE {table} AUTO_INCREMENT = 1"))
        db.commit()

        courses = build_courses(admin.id)
        db.add_all(courses)
        db.commit()

        lesson_count = sum(len(c.lessons) for c in courses)
        quiz_count = sum(1 for c in courses for l in c.lessons if l.quiz is not None)
        question_count = sum(
            len(l.quiz.questions) for c in courses for l in c.lessons if l.quiz is not None
        )
        choice_count = sum(
            len(qn.choices)
            for c in courses
            for l in c.lessons
            if l.quiz is not None
            for qn in l.quiz.questions
        )
        print(
            f"\nSeeded {len(courses)} courses, {lesson_count} lessons, "
            f"{quiz_count} quizzes, {question_count} questions, {choice_count} choices."
        )
    finally:
        db.close()


if __name__ == "__main__":
    main()
