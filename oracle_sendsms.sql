-- This SQL file contains a stored procedure for sending SMS messages using the Twilio API.
-- The procedure, `send_sms`, is designed to send SMS messages to one or more recipients by interacting with Twilio's REST API.
-- It fulfills the business requirement of programmatically sending SMS notifications from an Oracle database.

CREATE OR REPLACE PROCEDURE send_sms(p_user     IN VARCHAR2, -- Twilio user name
                                     p_pass     IN VARCHAR2, -- Twilio password
                                     p_from     IN VARCHAR2, -- Twilio From phone number
                                     p_to       IN VARCHAR2, -- Phone number of SMS recipient(s) colon delimited.
                                     p_sms_body IN VARCHAR2) IS
  t_http_req       utl_http.req;  -- HTTP request object
  t_http_resp      utl_http.resp; -- HTTP response object
  lv_resp_line     VARCHAR2(32767); -- Variable to store a single line of the HTTP response
  lv_response_text CLOB; -- Variable to accumulate the full HTTP response

  -- Construct the Twilio API URL for sending SMS messages
  v_url          VARCHAR2(200) := 'https://api.twilio.com/2010-04-01/Accounts/' ||
                                  p_user || '/SMS/Messages.xml';
  lv_post_params VARCHAR2(30000); -- Parameters for the POST request
  lv_from        VARCHAR2(100); -- Sender's phone number
  lv_to          VARCHAR2(100); -- Recipient's phone number
  lv_sms_body    VARCHAR2(30000); -- SMS message body
  c_xml_response CLOB; -- Placeholder for XML response (currently unused)

  lv_recipients apex_application_global.vc_arr2; -- Array to hold multiple recipients
BEGIN
  c_xml_response := NULL; -- Initialize XML response placeholder
  lv_from        := p_from; -- Assign sender's phone number
  lv_sms_body    := p_sms_body; -- Assign SMS message body
  lv_recipients  := apex_util.string_to_table(p_to, ':'); -- Split recipients into an array using colon as delimiter
  FOR i IN 1 .. lv_recipients.count LOOP
    -- Construct POST parameters for the current recipient
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body;
    lv_post_params := utl_url.escape(lv_post_params); -- Escape POST parameters for URL encoding
    v_url          := utl_url.escape(v_url); -- Escape the URL for safe HTTP request
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio',
                        'password12'); -- Set the wallet for secure HTTP communication
    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1'); -- Begin the HTTP POST request
    utl_http.set_authentication(t_http_req, p_user, p_pass); -- Set basic authentication using Twilio credentials
    utl_http.set_header(t_http_req,
                        'Content-Type',
                        'application/x-www-form-urlencoded'); -- Set content type for form data
    utl_http.set_header(t_http_req,
                        'Content-Length',
                        length(lv_post_params)); -- Set content length for the POST data
    utl_http.write_text(t_http_req, lv_post_params); -- Write the POST parameters to the request
    t_http_resp := utl_http.get_response(t_http_req); -- Get the HTTP response
    LOOP
      BEGIN
        lv_resp_line := NULL; -- Initialize response line
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE); -- Read a line from the HTTP response
        lv_response_text := lv_response_text || lv_resp_line; -- Append the line to the full response text
      EXCEPTION 
      WHEN utl_http.end_of_body THEN -- Handle end of HTTP response body
        utl_http.end_response(t_http_resp); -- End the HTTP response
      END;
    END LOOP;
    utl_http.end_response(t_http_resp); -- Ensure the HTTP response is properly closed
    dbms_output.put_line(lv_response_text); -- Output the full response text to the console
    lv_response_text := NULL; -- Reset the response text for the next iteration
  END LOOP;
END send_sms;