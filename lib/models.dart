import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Campaign {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double targetAmount;
  final double currentAmount;
  final String category;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
  });

  double get progressPercentage => (currentAmount / targetAmount) * 100;
}

class DonationHistoryItem {
  final int id;
  final String campaignName;
  final double amount;
  final DateTime date;
  final String status;

  DonationHistoryItem({
    required this.id,
    required this.campaignName,
    required this.amount,
    required this.date,
    required this.status,
  });
}

class User {
  String name;
  String email;
  String phone;
  String profileImageUrl;

  User({
    this.name = 'John Doe',
    this.email = 'johndoe@example.com',
    this.phone = '+1 234 567 890',
    this.profileImageUrl = 'https://picsum.photos/seed/profile_default/150/150',
  });
}

class VolunteerCampaign {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int maxVolunteers;
  final int registeredVolunteers;
  final String requirements;
  final String benefits;

  VolunteerCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.maxVolunteers,
    required this.registeredVolunteers,
    required this.requirements,
    required this.benefits,
  });

  int get availableSpots => maxVolunteers - registeredVolunteers;
}