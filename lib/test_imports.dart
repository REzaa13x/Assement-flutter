// This is a simple test file to verify all imports work correctly
import 'package:flutter/material.dart';
import 'models.dart';
import 'pages/home_page.dart';
import 'pages/list_campaign_page.dart';
import 'pages/campaign_detail_page.dart';
import 'pages/donation_form_page.dart';
import 'pages/payment_success_page.dart';
import 'pages/about_us_page.dart';
import 'pages/how_it_works_page.dart';
import 'pages/volunteer_page.dart';
import 'pages/start_campaign_page.dart';
import 'pages/profile_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/donation_history_page.dart';
import 'widgets/custom_widgets.dart';

// This file is just to verify that all imports work correctly
void main() {
  // All imports are successfully resolved
  print("All imports resolved successfully!");
  
  // Test creating a campaign object
  Campaign testCampaign = Campaign(
    id: 1,
    title: 'Test Campaign',
    description: 'Test Description',
    imageUrl: 'https://via.placeholder.com/400x200',
    targetAmount: 1000000,
    currentAmount: 500000,
    category: 'Test',
  );
  
  print("Test campaign created: ${testCampaign.title}");
  
  // Test creating a donation history item
  DonationHistoryItem testHistory = DonationHistoryItem(
    id: 1,
    campaignName: 'Test Campaign',
    amount: 100000,
    date: DateTime.now(),
    status: 'Completed',
  );
  
  print("Test donation history created: ${testHistory.campaignName}");
  
  // Test creating a user
  User testUser = User();
  
  print("Test user created: ${testUser.name}");
}