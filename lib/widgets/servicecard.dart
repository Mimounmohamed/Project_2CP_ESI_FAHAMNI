import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../models/tutor_model.dart';
import '../models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final TutorModel tutor;
  final ServiceModel service;
  final bool showBookButton;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final Widget? trailingActions;

  const ServiceCard({
    super.key,
    required this.tutor,
    required this.service,
    this.showBookButton = true,
    this.primaryActionLabel = 'Book Now',
    this.onPrimaryAction,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
                elevation: 6,
                shadowColor: const Color(0xFF000080).withValues(alpha: 0.45),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(service.picture != "")
                          Image.network(
                            service.picture,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              "assets/images/default_service_img.png",
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if(service.picture == "")
                          Image.asset(
                            "assets/images/default_service_img.png",
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: const BoxConstraints(minHeight: 23, maxWidth: 140),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0x19000080),
                                  borderRadius: BorderRadius.circular(999)
                                ),
                                child: Center(
                                  child: Text(
                                    service.subject,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: const Color(0xFF000080),
                                      fontSize: 13,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                      letterSpacing: 0.50,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                service.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  height: 1.38,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(tutor.picture),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      tutor.firstName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w400,
                                        height: 1.43,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/images/time.svg",
                                    height: 20,
                                    width: 20,
                                    color: const Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      "${service.duration}min session",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w400,
                                        height: 1.43,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if(service.maxnum - service.enrollednum <= 10)
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/images/circle-alert.svg",
                                    height: 20,
                                    width: 20,
                                    color: const Color(0xFFDD0D0D),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      '${service.maxnum - service.enrollednum} places left',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFDD0D0D),
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w400,
                                        height: 1.43,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "${service.price.toInt()}DA",
                                    style: TextStyle(
                                      color: const Color(0xFF000080),
                                      fontSize: 20,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                      height: 1.56,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (trailingActions != null) trailingActions!,
                                  if (showBookButton)
                                    ElevatedButton(
                                      onPressed: onPrimaryAction ?? () {},
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF000080),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(100, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          )
                                      ),
                                      child: Center(
                                        child: Text(
                                          primaryActionLabel,
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              fontSize: 15
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    Positioned(
                        top: 15,
                        right: 16,
                        child: Container(
                          height: 25,
                          width: 50,
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                              SvgPicture.asset(
                                "assets/images/star.svg",
                                height:12 ,
                                width: 12,
                              ),
                              SizedBox(width: 2,),
                              Text(
                                tutor.averageRating.toString(),
                                style: TextStyle(
                                  color: const Color(0xFF1E293B),
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  height: 1.33,
                                ),
                              )
                              ],
                            ),
                          ),
                        )
                    ),
                  ],
                ),
              ),
    );
  }
}
