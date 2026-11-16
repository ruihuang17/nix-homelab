// Linked into the Thunderbird profile by Nix (pomelo, tangerine).
// Edit dots/thunderbird/user.js in the repo, not the copy in the profile.

// -- account manager -----------------------------------------------------
user_pref("mail.accountmanager.accounts", "account4,account1,account2,account8");
user_pref("mail.accountmanager.defaultaccount", "account4");
user_pref("mail.accountmanager.localfoldersserver", "server8");
user_pref("mail.smtp.defaultserver", "smtp4");
user_pref("mail.smtpservers", "smtp4,smtp1,smtp2");

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

// -- account 4: Outlook.com personal (OAuth2) -----------------------------
// Numbered 4, not 3: account3/server3 were Proton, and a profile that
// already ran keeps server3's local cache directory in prefs.js.
// Settings from Thunderbird's ISPDB entry for hotmail.com. No clientid pref:
// Thunderbird's built-in Microsoft client works for personal accounts.
user_pref("mail.account.account4.server", "server4");
user_pref("mail.account.account4.identities", "id4");

user_pref("mail.server.server4.type", "imap");
user_pref("mail.server.server4.hostname", "outlook.office365.com");
user_pref("mail.server.server4.name", "rui.huang17@hotmail.com");
user_pref("mail.server.server4.userName", "rui.huang17@hotmail.com");
user_pref("mail.server.server4.port", 993);
user_pref("mail.server.server4.socketType", 3); // TLS
user_pref("mail.server.server4.authMethod", 10); // OAuth2
user_pref("mail.server.server4.login_at_startup", true);
user_pref("mail.server.server4.check_new_mail", true);
user_pref("mail.server.server4.namespace.personal", "\"\"");
user_pref("mail.server.server4.trash_folder_name", "Deleted");

user_pref("mail.identity.id4.useremail", "rui.huang17@hotmail.com");
user_pref("mail.identity.id4.fullName", "Rui Huang");
user_pref("mail.identity.id4.smtpServer", "smtp4");
user_pref("mail.identity.id4.valid", true);
user_pref("mail.identity.id4.fcc", true);
user_pref("mail.identity.id4.fcc_folder", "imap://rui.huang17%40hotmail.com@outlook.office365.com/Sent");
user_pref("mail.identity.id4.draft_folder", "imap://rui.huang17%40hotmail.com@outlook.office365.com/Drafts");

user_pref("mail.smtpserver.smtp4.type", "smtp");
user_pref("mail.smtpserver.smtp4.hostname", "smtp-mail.outlook.com");
user_pref("mail.smtpserver.smtp4.port", 587);
user_pref("mail.smtpserver.smtp4.try_ssl", 2); // STARTTLS
user_pref("mail.smtpserver.smtp4.authMethod", 10); // OAuth2
user_pref("mail.smtpserver.smtp4.username", "rui.huang17@hotmail.com");

// -- account 8: Local Folders --------------------------------------------
// Declared here so Thunderbird never picks a number that an account above
// later takes over (the original Local Folders was server3, which the old
// Proton account overwrote). 5-7 are skipped: pomelo's prefs.js used them.
user_pref("mail.account.account8.server", "server8");

user_pref("mail.server.server8.type", "none");
user_pref("mail.server.server8.hostname", "Local Folders");
user_pref("mail.server.server8.name", "Local Folders");
user_pref("mail.server.server8.userName", "nobody");
user_pref("mail.server.server8.directory-rel", "[ProfD]Mail/Local Folders");
