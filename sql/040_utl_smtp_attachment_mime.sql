DECLARE
    l_connection     UTL_SMTP.CONNECTION;

    c_smtp_host CONSTANT VARCHAR2(100) :=
        'smtp.email.eu-frankfurt-1.oci.oraclecloud.com';

    c_sender CONSTANT VARCHAR2(100) :=
        'adb@mail.lslabsessions.com';

    c_recipient CONSTANT VARCHAR2(100) :=
        'info@lslabsessions.com';

    l_date            VARCHAR2(100);
    l_message_id      VARCHAR2(200);
    l_boundary        VARCHAR2(100);

    l_body            VARCHAR2(32767);
    l_attachment      VARCHAR2(32767);

    l_attachment_raw  RAW(32767);
    l_attachment_b64  RAW(32767);
    l_base64_text     VARCHAR2(32767);

    l_pos             PLS_INTEGER := 1;

BEGIN
    -- RFC-style Date header in UTC
    l_date :=
        TO_CHAR(
            SYS_EXTRACT_UTC(SYSTIMESTAMP),
            'Dy, DD Mon YYYY HH24:MI:SS',
            'NLS_DATE_LANGUAGE=American'
        ) || ' +0000';

    -- Unique Message-ID and MIME boundary.
    l_message_id :=
        '<' ||
        LOWER(RAWTOHEX(SYS_GUID())) ||
        '@mail.lslabsessions.com>';

    l_boundary :=
        '----LSLABS-' || LOWER(RAWTOHEX(SYS_GUID()));

    -- Plain-text message body
    l_body :=
        'Hello from Oracle Autonomous Database.' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF ||
        'This email contains a CSV attachment generated in PL/SQL.' ||
        UTL_TCP.CRLF ||
        'The attachment is encoded manually using MIME and Base64.';

    -- CSV attachment generated with UTF-8 characters
    l_attachment :=
        'ROW_ID,DESCRIPTION' || UTL_TCP.CRLF ||
        '1,"Olá from ADB"'   || UTL_TCP.CRLF ||
        '2,"café"'           || UTL_TCP.CRLF ||
        '3,"coração"'        || UTL_TCP.CRLF;


    -- Convert the attachment to UTF-8 bytes
    l_attachment_raw :=
        UTL_I18N.STRING_TO_RAW(
            l_attachment,
            'AL32UTF8'
        );

    l_attachment_b64 :=
        UTL_ENCODE.BASE64_ENCODE(
            l_attachment_raw
        );

     -- Base64 consists only of ASCII characters (safe to cast to VARCHAR2 for output)
    l_base64_text :=
        UTL_RAW.CAST_TO_VARCHAR2(
            l_attachment_b64
        );

    l_connection :=
        UTL_SMTP.OPEN_CONNECTION(
            host => c_smtp_host,
            port => 587
        );

    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

    UTL_SMTP.STARTTLS(l_connection);

    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

    UTL_SMTP.SET_CREDENTIAL(
        c          => l_connection,
        credential => 'LSLABS_EMAIL_CRED',
        schemes    => 'PLAIN'
    );

    /*
     * SMTP envelope.
     */
    UTL_SMTP.MAIL(
        l_connection,
        c_sender
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_recipient
    );

    -- Start RFC 5322 / MIME message
    UTL_SMTP.OPEN_DATA(l_connection);

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Date: ' || l_date || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Message-ID: ' || l_message_id || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'From: LS Labs ADB <' || c_sender || '>' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'To: ' || c_recipient || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Subject: LS Labs - UTL_SMTP MIME attachment test' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'MIME-Version: 1.0' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Type: multipart/mixed; boundary="' ||
        l_boundary || '"' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF
    );

    -- MIME part 1: message body
    UTL_SMTP.WRITE_DATA(
        l_connection,
        '--' || l_boundary || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Type: text/plain; charset=UTF-8' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Transfer-Encoding: 8bit' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_RAW_DATA(
        l_connection,
        UTL_I18N.STRING_TO_RAW(
            l_body || UTL_TCP.CRLF,
            'AL32UTF8'
        )
    );

    -- MIME part 2: CSV attachment.
    UTL_SMTP.WRITE_DATA(
        l_connection,
        UTL_TCP.CRLF ||
        '--' || l_boundary || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Type: text/csv; charset=UTF-8; ' ||
        'name="lslabs_report.csv"' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Transfer-Encoding: base64' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Disposition: attachment; ' ||
        'filename="lslabs_report.csv"' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF
    );

    WHILE l_pos <= LENGTH(l_base64_text) LOOP
        UTL_SMTP.WRITE_DATA(
            l_connection,
            SUBSTR(l_base64_text, l_pos, 76) ||
            UTL_TCP.CRLF
        );

        l_pos := l_pos + 76;
    END LOOP;

    -- Close multipart MIME message.
    UTL_SMTP.WRITE_DATA(
        l_connection,
        '--' || l_boundary || '--' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.CLOSE_DATA(l_connection);
    UTL_SMTP.QUIT(l_connection);

EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            UTL_SMTP.QUIT(l_connection);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE;
END;
/