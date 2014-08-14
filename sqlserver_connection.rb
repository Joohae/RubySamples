#
=begin
  To run the code, you need to install following gems,
  and add a ODBC Data Source (DSN) on the computer.
  
  gem install dbi dbd-odbc ruby-odbc
=end

begin
  dbh = DBI.connect('dbi:ODBC:MYDSN', 'userid', 'password')

  log_stmt   = dbh.prepare("INSERT INTO email_log (email_from,email_to,log_message) VALUES(?, ?, ?)")
  stmtu_sent = dbh.prepare("UPDATE email_queue SET sent_date = CURRENT_TIMESTAMP, status = 'S' WHERE queue_id = ?")
  stmtu_err  = dbh.prepare("UPDATE email_queue SET retry_count = isNull(retry_count, 0) + 1, status = ? WHERE queue_id = ?")

  dbh.select_all("SELECT * FROM email_queue WHERE status = 'R'") do | row |
    begin
      MailSender.send_mail row # check send_email_with_mailgem.rb
      stmtu_sent.execute(row['queue_id'])
    rescue => e
      log_stmt.execute(row['email_from'], row['email_to'], e.message)
      if e.message =~ /^invalid/i || row['retry_count'] > 5 then
        stmtu_err.execute('E', row['queue_id'])
      else
        stmtu_err.execute('R', row['queue_id'])
      end
    end
  end
rescue DBI::DatabaseError => e
  log_stmt.execute('ERROR', 'DB', "Code: #{e.err}, #{e.errstr}") if log_stmt
ensure
  log_stmt.finish   if log_stmt
  stmtu_sent.finish if stmtu_sent
  stmtu_err.finish  if stmtu_err
  if dbh then
    dbh.commit
    dbh.disconnect
  end
end

=begin
Note. table definition of email_queue

  SET ANSI_NULLS ON;
  GO
  SET QUOTED_IDENTIFIER ON;
  GO
  CREATE TABLE [dbo].[email_queue] (
  [queue_id] int IDENTITY(1, 1) NOT NULL,
  [username] varchar(256) NULL,
  [password] varchar(50) NULL,
  [email_from] varchar(256) NULL,
  [email_from_name] varchar(50) NULL,
  [email_reply] varchar(256) NULL,
  [email_reply_name] varchar(50) NULL,
  [email_to] varchar(256) NULL,
  [email_to_name] varchar(50) NULL,
  [email_subject] varchar(128) NULL,
  [email_body] text NULL,
  [reqeust_from] varchar(256) NULL,
  [request_id] varchar(50) NULL,
  [request_date] datetime NULL,
  [sent_date] datetime NULL,
  [error_msg] varchar(256) NULL,
  [retry_count] int NOT NULL,
  [status] char(1) NOT NULL)
  ON [PRIMARY]
  TEXTIMAGE_ON [PRIMARY]
  WITH (DATA_COMPRESSION = NONE);
  GO
  ALTER TABLE [dbo].[email_queue] SET (LOCK_ESCALATION = TABLE);  
  GO

=end

=begin
  Note. Table definition of email_log
  
  SET ANSI_NULLS ON;
  GO
  SET QUOTED_IDENTIFIER ON;
  GO
  CREATE TABLE [dbo].[email_log] (
  [log_id] int IDENTITY(1, 1) NOT NULL,
  [cr_date] datetime NOT NULL,
  [email_from] nvarchar(250) NULL,
  [email_to] nvarchar(250) NULL,
  [log_message] text NULL)
  ON [PRIMARY]
  TEXTIMAGE_ON [PRIMARY]
  WITH (DATA_COMPRESSION = NONE);
  GO
  ALTER TABLE [dbo].[email_log] SET (LOCK_ESCALATION = TABLE);
  GO

=end