// // for email otp method 
// // lib/services/email_service.dart
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/foundation.dart';

// class EmailService {
//   // ⚠️ IMPORTANT: Replace these with your actual values from SendGrid
//   static const String _sendGridApiKey =
//       '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';
//   static const String _fromEmail = 'aqibmasood334@gmail.com';
//   static const String _fromName = 'AgriVision';

//   static Future<bool> sendOTPEmail({
//     required String toEmail,
//     required String otp,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('https://api.sendgrid.com/v3/mail/send'),
//         headers: {
//           'Authorization': 'Bearer $_sendGridApiKey',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'personalizations': [
//             {
//               'to': [
//                 {'email': toEmail},
//               ],
//               'subject': 'Verify Your Email - AgriVision',
//             },
//           ],
//           'from': {'email': _fromEmail, 'name': _fromName},
//           'content': [
//             {'type': 'text/html', 'value': _buildEmailHTML(otp)},
//           ],
//         }),
//       );

//       if (response.statusCode == 202) {
//         debugPrint(' OTP email sent successfully to $toEmail');
//         return true;
//       } else {
//         debugPrint(
//           ' SendGrid error: ${response.statusCode} - ${response.body}',
//         );
//         return false;
//       }
//     } catch (e) {
//       debugPrint('Error sending OTP email: $e');
//       return false;
//     }
//   }

//   static String _buildEmailHTML(String otp) {
//     return '''
// <!DOCTYPE html>
// <html>
// <head>
//   <meta charset="UTF-8">
//   <meta name="viewport" content="width=device-width, initial-scale=1.0">
// </head>
// <body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
//   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4; padding: 20px;">
//     <tr>
//       <td align="center">
//         <table width="600" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          
//           <!-- Header -->
//           <tr>
//             <td style="background: linear-gradient(135deg, #2E7D32, #66BB6A); padding: 40px; text-align: center; color: #ffffff;">
//               <h1 style="margin: 0; font-size: 32px;">🌱 AgriVision</h1>
//               <p style="margin: 10px 0 0 0; font-size: 16px;">Email Verification</p>
//             </td>
//           </tr>
          
//           <!-- Body -->
//           <tr>
//             <td style="padding: 40px;">
//               <h2 style="color: #333; margin: 0 0 20px 0;">Hello!</h2>
//               <p style="color: #666; line-height: 1.6; margin: 0 0 30px 0;">
//                 Thank you for registering with AgriVision. Please use the code below to verify your email address:
//               </p>
              
//               <!-- OTP Box -->
//               <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f1f8e9; border-radius: 8px; padding: 30px; margin: 30px 0;">
//                 <tr>
//                   <td align="center">
//                     <p style="margin: 0; color: #666; font-size: 14px;">Your Verification Code</p>
//                     <div style="font-size: 40px; font-weight: bold; letter-spacing: 15px; color: #2E7D32; margin: 15px 0;">$otp</div>
//                     <p style="margin: 10px 0 0 0; color: #999; font-size: 12px;">Valid for 10 minutes</p>
//                   </td>
//                 </tr>
//               </table>
              
//               <p style="color: #666; line-height: 1.6; margin: 30px 0 0 0;">
//                 <strong>Note:</strong> If you didn't request this code, please ignore this email.
//               </p>
              
//               <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
              
//               <p style="color: #999; font-size: 14px; text-align: center; margin: 0;">
//                 Having trouble? Contact us at 
//                 <a href="mailto:support@agrivision.com" style="color: #2E7D32; text-decoration: none;">support@agrivision.com</a>
//               </p>
//             </td>
//           </tr>
          
//           <!-- Footer -->
//           <tr>
//             <td style="background-color: #f5f5f5; padding: 20px; text-align: center; color: #999; font-size: 12px;">
//               <p style="margin: 5px 0;">&copy; 2025 AgriVision. All rights reserved.</p>
//               <p style="margin: 5px 0;">Smart Farming, Smart Trading</p>
//             </td>
//           </tr>
          
//         </table>
//       </td>
//     </tr>
//   </table>
// </body>
// </html>
//     ''';
//   }
// }
