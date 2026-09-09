<template>
  <div class="page-header">
    <div>
      <h2>Privacy Policy</h2>
      <p>Last updated: September 9, 2026</p>
    </div>
  </div>

  <div class="surface-card legal-card">
    <p>
      This Privacy Policy describes what information the Learning Platform app and admin panel
      ("the Service") collects, how it is used, and how it is protected.
    </p>

    <h3>Information we collect</h3>
    <ul>
      <li>Account details: full name, email address, phone number, and password (stored only as a salted hash, never in plain text).</li>
      <li>Optional profile details: gender, profile photo.</li>
      <li>Learning activity: course enrollments, lesson progress, quiz attempts and scores, certificates earned, and game results.</li>
      <li>Content you submit: course reviews, ratings, and feedback or support messages.</li>
      <li>Files you upload: profile photos and any documents/media submitted through the app.</li>
      <li>Basic technical data needed to operate the Service, such as request logs used for rate limiting and security.</li>
    </ul>

    <h3>How we use this information</h3>
    <ul>
      <li>To create and manage your account, and to authenticate you when you sign in.</li>
      <li>To deliver course content, track your progress, and issue certificates.</li>
      <li>To show reviews and leaderboard results to other users where the feature is inherently public (e.g. course reviews, game leaderboards).</li>
      <li>To respond to feedback and support requests you submit.</li>
      <li>To keep the Service secure and prevent abuse.</li>
    </ul>

    <h3>What we don't do</h3>
    <ul>
      <li>We do not sell your personal information.</li>
      <li>We do not share your data with third parties for their own marketing purposes.</li>
    </ul>

    <h3>Data retention</h3>
    <p>
      We retain account and activity data for as long as your account is active. You may request
      deletion of your account and associated data at any time by contacting support through the
      in-app Feedback screen.
    </p>

    <h3>Your choices</h3>
    <ul>
      <li>You can review and update your profile information at any time from the Profile screen.</li>
      <li>You can change your password or log out of the app at any time.</li>
      <li>You can request account deletion by contacting us.</li>
    </ul>

    <h3>Contact</h3>
    <p>Questions about this policy can be sent through the in-app Feedback screen.</p>
  </div>
</template>

<style scoped>
.legal-card {
  max-width: 720px;
  margin: 0 auto;
}

.legal-card h3 {
  margin: 24px 0 10px;
  font-size: 15px;
  font-weight: 700;
}

.legal-card h3:first-child {
  margin-top: 0;
}

.legal-card p {
  margin: 0 0 10px;
  color: var(--text-primary);
  font-size: 13.5px;
  line-height: 1.6;
}

.legal-card ul {
  margin: 0 0 10px;
  padding-left: 20px;
}

.legal-card li {
  margin-bottom: 6px;
  font-size: 13.5px;
  line-height: 1.6;
  color: var(--text-primary);
}
</style>
