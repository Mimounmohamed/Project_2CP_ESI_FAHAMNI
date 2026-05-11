import 'package:flutter/material.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/utils/image_utils.dart';

class FavoriteTeachersPage extends StatelessWidget {
  final List<TutorModel> favoriteTutors;

  const FavoriteTeachersPage({super.key, required this.favoriteTutors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
        ),
        title: const Text(
          "Favorite Teachers",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
          ),
        ),
        centerTitle: true,
      ),
      body: favoriteTutors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No favorite teachers yet",
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: favoriteTutors.length,
              itemBuilder: (context, index) {
                final tutor = favoriteTutors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TutorProfilePage(tutorId: tutor.uid),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000080).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFFF1F5F9),
                              backgroundImage: safeImage(
                                tutor.picture,
                                defaultAsset: tutor.gender.name == "female" 
                                    ? "assets/images/tutorfemale.png" 
                                    : "assets/images/tutormale.png",
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${tutor.firstName} ${tutor.lastName}",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tutor.expertiseDomain,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF000080),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              tutor.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
