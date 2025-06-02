-- This SQL script defines a stored procedure `send_sms` that interacts with the Twilio API to send SMS messages.
-- It fulfills the business requirement of sending SMS notifications to specified recipients using Twilio's service.

CREATE OR REPLACE PROCEDURE send_sms(p_user     IN VARCHAR2, -- Twilio user name
                                     p_pass     IN VARCHAR2, -- Twilio password
                                     p_from     IN VARCHAR2, -- Twilio From phone number
                                     p_to       IN VARCHAR2, -- Phone number of SMS recipient(s) colon delimited.
                                     p_sms_body IN VARCHAR2) IS
  t_http_req       utl_http.req;  -- HTTP request object
  t_http_resp      utl_http.resp; -- HTTP response object
  lv_resp_line     VARCHAR2(32767); -- Variable to store each line of the HTTP response
  lv_response_text CLOB; -- Variable to accumulate the full HTTP response

  v_url          VARCHAR2(200) := 'https://api.twilio.com/2010-04-01/Accounts/' ||
                                  p_user || '/SMS/Messages.xml'; -- URL for Twilio API endpoint
  lv_post_params VARCHAR2(30000); -- Parameters for the POST request
  lv_from        VARCHAR2(100); -- Sender's phone number
  lv_to          VARCHAR2(100); -- Recipient's phone number
  lv_sms_body    VARCHAR2(30000); -- Body of the SMS message
  c_xml_response CLOB; -- Placeholder for XML response

  lv_recipients apex_application_global.vc_arr2; -- Array to hold recipient phone numbers
BEGIN
  c_xml_response := NULL; -- Initialize XML response variable
  lv_from        := p_from; -- Assign sender's phone number
  lv_sms_body    := p_sms_body; -- Assign SMS body
  lv_recipients  := apex_util.string_to_table(p_to, ':'); -- Split recipient phone numbers into an array

  FOR i IN 1 .. lv_recipients.count LOOP -- Loop through each recipient
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body; -- Construct POST parameters
    lv_post_params := utl_url.escape(lv_post_params); -- Escape special characters in POST parameters
    v_url          := utl_url.escape(v_url); -- Escape special characters in URL

    -- Set up the wallet for secure connection
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio',
                        'password12'); -- TODO: Ensure the wallet path and password are correct. This is crucial for establishing a secure connection.

    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1'); -- Begin HTTP POST request
    utl_http.set_authentication(t_http_req, p_user, p_pass); -- Set HTTP authentication using Twilio credentials
    utl_http.set_header(t_http_req,
                        'Content-Type',
                        'application/x-www-form-urlencoded'); -- Set content type for POST request
    utl_http.set_header(t_http_req,
                        'Content-Length',
                        length(lv_post_params)); -- Set content length for POST request
    utl_http.write_text(t_http_req, lv_post_params); -- Write POST parameters to request

    t_http_resp := utl_http.get_response(t_http_req); -- Get HTTP response

    LOOP -- Loop to read the HTTP response line by line
      BEGIN
        lv_resp_line := NULL; -- Initialize response line variable
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE); -- Read a line from the response
        lv_response_text := lv_response_text || lv_resp_line; -- Accumulate response text
      EXCEPTION 
      WHEN utl_http.end_of_body THEN -- Handle end of HTTP response body
        utl_http.end_response(t_http_resp); -- End the HTTP response
      END;
    END LOOP;

    utl_http.end_response(t_http_resp); -- Ensure response is properly ended
    dbms_output.put_line(lv_response_text); -- Output the accumulated response text
    lv_response_text := NULL; -- Reset response text for next iteration
  END LOOP;
END send_sms;