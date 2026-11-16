// Linked into the Thunderbird profile by Nix (pomelo, tangerine).
// Edit dots/thunderbird/user.js in the repo, not the copy in the profile.

// -- account manager -----------------------------------------------------
user_pref("mail.accountmanager.accounts", "account1,account2,account3");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpservers", "smtp1,smtp2,smtp3");

// -- account 1: UWaterloo (Microsoft 365, OAuth2) ------------------------
user_pref("mail.account.account1.server", "server1");
user_pref("mail.account.account1.identities", "id1");

user_pref("mail.server.server1.type", "imap");
user_pref("mail.server.server1.hostname", "outlook.office365.com");
user_pref("mail.server.server1.name", "r232huan@uwaterloo.ca");
user_pref("mail.server.server1.userName", "r232huan@uwaterloo.ca");
user_pref("mail.server.server1.port", 993);
user_pref("mail.server.server1.socketType", 3); // TLS
user_pref("mail.server.server1.authMethod", 10); // OAuth2
user_pref("mail.server.server1.clientid", "ab787c2f-64f9-4043-afc6-ae787b788dad");
user_pref("mail.server.server1.login_at_startup", true);
user_pref("mail.server.server1.check_new_mail", true);
user_pref("mail.server.server1.namespace.personal", "\"\"");
user_pref("mail.server.server1.trash_folder_name", "Deleted Items");

user_pref("mail.identity.id1.useremail", "r232huan@uwaterloo.ca");
user_pref("mail.identity.id1.fullName", "Rui Huang");
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.fcc", true);
user_pref("mail.identity.id1.fcc_folder", "imap://r232huan%40uwaterloo.ca@outlook.office365.com/Sent Items");
user_pref("mail.identity.id1.draft_folder", "imap://r232huan%40uwaterloo.ca@outlook.office365.com/Drafts");

user_pref("mail.smtpserver.smtp1.type", "smtp");
user_pref("mail.smtpserver.smtp1.hostname", "smtp.office365.com");
user_pref("mail.smtpserver.smtp1.port", 587);
user_pref("mail.smtpserver.smtp1.try_ssl", 2); // STARTTLS
user_pref("mail.smtpserver.smtp1.authMethod", 10); // OAuth2
user_pref("mail.smtpserver.smtp1.username", "r232huan@uwaterloo.ca");

// -- account 2: Stalwart (kanidm password, username `rhuang`) -------------
user_pref("mail.account.account2.server", "server2");
user_pref("mail.account.account2.identities", "id2");

user_pref("mail.server.server2.type", "imap");
user_pref("mail.server.server2.hostname", "mail.estrogenuinely.ca");
user_pref("mail.server.server2.name", "rui@estrogenuinely.ca");
user_pref("mail.server.server2.userName", "rhuang");
user_pref("mail.server.server2.port", 993);
user_pref("mail.server.server2.socketType", 3); // TLS
user_pref("mail.server.server2.authMethod", 3); // normal password
user_pref("mail.server.server2.login_at_startup", true);
user_pref("mail.server.server2.check_new_mail", true);
user_pref("mail.server.server2.namespace.personal", "\"\"");
user_pref("mail.server.server2.namespace.other_users", "\"Shared Folders\"");
user_pref("mail.server.server2.trash_folder_name", "Deleted Items");

user_pref("mail.identity.id2.useremail", "rui@estrogenuinely.ca");
user_pref("mail.identity.id2.fullName", "Rui Huang");
user_pref("mail.identity.id2.smtpServer", "smtp2");
user_pref("mail.identity.id2.valid", true);
user_pref("mail.identity.id2.fcc", true);
user_pref("mail.identity.id2.fcc_folder", "imap://rhuang@mail.estrogenuinely.ca/Sent Items");
user_pref("mail.identity.id2.draft_folder", "imap://rhuang@mail.estrogenuinely.ca/Drafts");

user_pref("mail.smtpserver.smtp2.type", "smtp");
user_pref("mail.smtpserver.smtp2.hostname", "mail.estrogenuinely.ca");
user_pref("mail.smtpserver.smtp2.port", 465);
user_pref("mail.smtpserver.smtp2.try_ssl", 3); // implicit TLS
user_pref("mail.smtpserver.smtp2.authMethod", 3); // normal password
user_pref("mail.smtpserver.smtp2.username", "rhuang");

// -- account 3: Proton Mail through Proton Bridge (localhost, STARTTLS) ---
// Bridge must be running. Its password is the Bridge-generated one, not
// the Proton account password.
user_pref("mail.account.account3.server", "server3");
user_pref("mail.account.account3.identities", "id3");

user_pref("mail.server.server3.type", "imap");
user_pref("mail.server.server3.hostname", "127.0.0.1");
user_pref("mail.server.server3.name", "rui.huang17@pm.me");
user_pref("mail.server.server3.userName", "rui.huang17@pm.me");
user_pref("mail.server.server3.port", 1143);
user_pref("mail.server.server3.socketType", 2); // STARTTLS
user_pref("mail.server.server3.authMethod", 3); // normal password
user_pref("mail.server.server3.login_at_startup", true);
user_pref("mail.server.server3.check_new_mail", true);
user_pref("mail.server.server3.trash_folder_name", "Trash");

user_pref("mail.identity.id3.useremail", "rui.huang17@pm.me");
user_pref("mail.identity.id3.fullName", "Rui Huang");
user_pref("mail.identity.id3.smtpServer", "smtp3");
user_pref("mail.identity.id3.valid", true);
// Proton files sent mail itself, so a copy from Thunderbird would duplicate.
user_pref("mail.identity.id3.fcc", false);
user_pref("mail.identity.id3.draft_folder", "imap://rui.huang17%40pm.me@127.0.0.1/Drafts");

user_pref("mail.smtpserver.smtp3.type", "smtp");
user_pref("mail.smtpserver.smtp3.hostname", "127.0.0.1");
user_pref("mail.smtpserver.smtp3.port", 1025);
user_pref("mail.smtpserver.smtp3.try_ssl", 2); // STARTTLS
user_pref("mail.smtpserver.smtp3.authMethod", 3); // normal password
user_pref("mail.smtpserver.smtp3.username", "rui.huang17@pm.me");
