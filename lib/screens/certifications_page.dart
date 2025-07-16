import 'package:flutter/material.dart';
import 'package:living/models/certification_model.dart';
import 'package:living/services/certification_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/category_constants.dart';

class CertificationsPage extends StatefulWidget {
  const CertificationsPage({super.key});

  @override
  State<CertificationsPage> createState() => _CertificationsPageState();
}

class _CertificationsPageState extends State<CertificationsPage> {
  List<Certification> certifications = [];
  bool isLoading = true;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      certifications = await CertificationDAO.getAllCertifications();
      
      // If no certifications exist, add sample data
      if (certifications.isEmpty) {
        await _addSampleCertifications();
        certifications = await CertificationDAO.getAllCertifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load certifications: $e',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _addSampleCertifications() async {
    try {
      final sampleCertifications = [
        Certification(
          key: '',
          name: 'USDA Organic',
          description: 'Certifies that agricultural products are produced using organic farming methods that exclude the use of synthetic pesticides, fertilizers, and genetically modified organisms.',
          category: 'Organic',
          logoUrl: '',
          criteria: [
            'No synthetic pesticides or fertilizers',
            'No genetically modified organisms (GMOs)',
            'Organic feed for livestock',
            'No antibiotics or growth hormones',
            'Maintain soil health and biodiversity'
          ],
          verificationProcess: 'Annual inspections by USDA-accredited certifying agents, including farm visits, record reviews, and residue testing.',
          benefits: 'Supports environmental sustainability, reduces chemical exposure, and promotes soil health. Organic products often have higher nutritional value and support local farming communities.',
          isVerified: true,
        ),
        Certification(
          key: '',
          name: 'Fair Trade Certified',
          description: 'Ensures that products are produced under fair labor conditions and that farmers and workers receive fair compensation for their work.',
          category: 'Fair Trade',
          logoUrl: '',
          criteria: [
            'Fair wages and working conditions',
            'No child or forced labor',
            'Democratic organization of workers',
            'Environmental protection standards',
            'Community development investments'
          ],
          verificationProcess: 'Regular audits by independent third-party certifiers, including worker interviews, facility inspections, and documentation reviews.',
          benefits: 'Improves livelihoods of farmers and workers, supports community development projects, and ensures ethical production practices.',
          isVerified: true,
        ),
        Certification(
          key: '',
          name: 'Energy Star',
          description: 'Identifies energy-efficient products and buildings that meet strict energy performance standards set by the EPA.',
          category: 'Energy Star',
          logoUrl: '',
          criteria: [
            'Meets strict energy efficiency guidelines',
            'Third-party testing and verification',
            'Significant energy savings compared to standard models',
            'Maintains performance and features',
            'Comprehensive product testing'
          ],
          verificationProcess: 'Products must be tested in EPA-recognized laboratories and meet specific energy efficiency criteria for their category.',
          benefits: 'Reduces energy consumption and utility bills, lowers greenhouse gas emissions, and helps protect the environment while maintaining product performance.',
          isVerified: true,
        ),
        Certification(
          key: '',
          name: 'FSC (Forest Stewardship Council)',
          description: 'Certifies that wood and paper products come from responsibly managed forests that provide environmental, social, and economic benefits.',
          category: 'Forest Stewardship',
          logoUrl: '',
          criteria: [
            'Sustainable forest management practices',
            'Protection of biodiversity and wildlife',
            'Respect for indigenous peoples\' rights',
            'Worker safety and fair labor practices',
            'Chain of custody tracking'
          ],
          verificationProcess: 'Independent audits by FSC-accredited certification bodies, including forest assessments, stakeholder consultation, and chain of custody verification.',
          benefits: 'Protects forests and wildlife habitats, supports local communities, and ensures sustainable wood and paper production.',
          isVerified: true,
        ),
        Certification(
          key: '',
          name: 'MSC (Marine Stewardship Council)',
          description: 'Certifies sustainable seafood that comes from well-managed fisheries that minimize environmental impact.',
          category: 'Marine Stewardship',
          logoUrl: '',
          criteria: [
            'Sustainable fish stocks',
            'Minimal environmental impact',
            'Effective fishery management',
            'Chain of custody tracking',
            'Regular reassessment'
          ],
          verificationProcess: 'Comprehensive assessment by independent certifiers, including scientific review, stakeholder consultation, and regular monitoring.',
          benefits: 'Helps protect ocean ecosystems, ensures sustainable seafood supply, and supports responsible fishing practices.',
          isVerified: true,
        ),
      ];

      for (final certification in sampleCertifications) {
        await CertificationDAO.addCertification(certification);
      }
    } catch (e) {
      print('Failed to add sample certifications: $e');
    }
  }

  List<Certification> get filteredCertifications {
    if (selectedCategory == 'All') {
      return certifications;
    }
    return certifications.where((cert) => cert.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: Stack(
                children: [
                  if (isLoading) const Positioned.fill(child: Loader()),
                  Column(
                    children: [
                      _buildInfoHeader(),
                      _buildCategoryFilter(),
                      Expanded(
                        child: _buildCertificationsList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Footer(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getBottomNavHeight(context) + 12,
        ),
        child: FloatingActionButton(
          onPressed: _showAddCertificationDialog,
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          child: Icon(
            Icons.add,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      margin: ResponsiveHelper.getAdaptivePadding(context),
      padding: ResponsiveHelper.getAdaptivePadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.5),
            ),
            child: Icon(
              Icons.verified,
              color: AppColors.white,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Green Certifications',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                Text(
                  'Learn about eco-labels and sustainable product certifications that help you make informed environmental choices.',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.08,
      padding: ResponsiveHelper.getVerticalPadding(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.getHorizontalPadding(context),
        itemCount: kCertificationCategories.length,
        itemBuilder: (context, index) {
          final category = kCertificationCategories[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: AppColors.success,
              checkmarkColor: AppColors.white,
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: AppColors.success.withOpacity(0.3)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertificationsList() {
    if (filteredCertifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredCertifications.length,
      itemBuilder: (context, index) {
        final certification = filteredCertifications[index];
        return _buildCertificationCard(certification);
      },
    );
  }

    Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco_outlined,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
          Text(
            'No certifications found',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          Text(
            'Try selecting a different category or add a new certification.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() => isLoading = true);
              await _addSampleCertifications();
              await _loadData();
            },
            icon: Icon(Icons.add),
            label: Text('Add Sample Certifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(Certification certification) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: InkWell(
        onTap: () => _showCertificationDetail(certification),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                    height: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.5),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: AppColors.success,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certification.name,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                            vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.05,
                          ),
                                                      decoration: BoxDecoration(
                              color: certification.isVerified 
                                  ? AppColors.success.withOpacity(0.1) 
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.2),
                            ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                certification.isVerified ? Icons.check_circle : Icons.pending,
                                size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.6,
                                color: certification.isVerified ? AppColors.success : AppColors.warning,
                              ),
                              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                              Text(
                                certification.isVerified ? 'Verified' : 'Pending',
                                style: TextStyle(
                                  color: certification.isVerified ? AppColors.success : AppColors.warning,
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                certification.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.2),
                    ),
                    child: Text(
                      certification.category,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.6,
                    color: AppColors.secondaryText.withOpacity(0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCertificationDetail(Certification certification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
              ),
              child: Icon(
                Icons.verified,
                color: AppColors.success,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Expanded(
              child: Text(
                certification.name,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: ResponsiveHelper.getScreenWidth(context) * (ResponsiveHelper.isMobile(context) ? 0.95 : 0.8),
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 600,
            maxHeight: ResponsiveHelper.getScreenHeight(context) * (ResponsiveHelper.isMobile(context) ? 0.6 : 0.7),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                  ),
                  child: Text(
                    certification.description,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                Row(
                  children: [
                    Icon(
                      certification.isVerified ? Icons.check_circle : Icons.pending,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: certification.isVerified ? AppColors.success : AppColors.warning,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      certification.isVerified ? 'Verified Certification' : 'Pending Verification',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: certification.isVerified ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                _buildDetailSection('Certification Criteria', certification.criteria),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                _buildDetailSection('Benefits', [certification.benefits]),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                _buildDetailSection('Verification Process', [certification.verificationProcess]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        ...content.map((item) => Padding(
          padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showAddCertificationDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final criteriaController = TextEditingController();
    final benefitsController = TextEditingController();
    final verificationController = TextEditingController();
    String selectedCategory = 'Organic';
    String selectedCertificationType = 'USDA Organic';
    String selectedCriteria = '';
    String selectedBenefits = '';
    String selectedVerification = '';
    
    // Predefined criteria options (very short versions)
    final List<String> criteriaOptions = [
      'No pesticides', 'No GMOs', 'Organic feed', 'No antibiotics', 'Soil health',
      'Fair wages', 'No child labor', 'Worker rights', 'Environmental protection',
      'Community development', 'Energy efficiency', 'Third-party testing',
      'Energy savings', 'Performance', 'Product testing', 'Sustainable forestry',
      'Biodiversity', 'Indigenous rights', 'Worker safety', 'Chain tracking',
      'Sustainable fishing', 'Minimal impact', 'Fishery management', 'Regular assessment',
      'Sustainable development', 'Water efficiency', 'Energy optimization',
      'Resource selection', 'Indoor quality', 'Innovation', 'Impact assessment',
      'Legal accountability', 'Transparency', 'Stakeholder engagement',
      'Continuous improvement', 'Biodiversity conservation', 'Resource management',
      'Worker safety', 'Community engagement', 'Climate mitigation',
    ];
    
    // Predefined benefits options (very short versions)
    final List<String> benefitsOptions = [
      'Sustainability', 'Reduces exposure', 'Soil health', 'Higher nutrition',
      'Local communities', 'Better livelihoods', 'Community development',
      'Ethical production', 'Energy savings', 'Reduces emissions', 'Protects environment',
      'Performance', 'Wildlife protection', 'Community support', 'Sustainable production',
      'Ocean protection', 'Sustainable seafood', 'Responsible fishing', 'Reduces impact',
      'Health improvement', 'Cost savings', 'Social responsibility', 'Consumer attraction',
      'Positive change', 'Ecosystem protection', 'Sustainable business',
    ];
    
    // Predefined verification options (very short versions)
    final List<String> verificationOptions = [
      'Annual inspections', 'Farm visits', 'Residue testing', 'Third-party audits',
      'Worker interviews', 'Documentation review', 'EPA testing', 'Energy compliance',
      'FSC audits', 'Forest assessments', 'Chain verification', 'Independent assessment',
      'Scientific review', 'Regular monitoring', 'Third-party verification',
      'On-site inspections', 'Certification assessment', 'Stakeholder interviews',
      'Recertification', 'Alliance audits', 'Stakeholder consultation',
    ];
    
    // Predefined certification templates
    final Map<String, Map<String, dynamic>> certificationTemplates = {
      'USDA Organic': {
        'name': 'USDA Organic',
        'description': 'Certifies that agricultural products are produced using organic farming methods that exclude the use of synthetic pesticides, fertilizers, and genetically modified organisms.',
        'category': 'Organic',
        'criteria': 'No synthetic pesticides or fertilizers, No genetically modified organisms (GMOs), Organic feed for livestock, No antibiotics or growth hormones, Maintain soil health and biodiversity',
        'benefits': 'Supports environmental sustainability, reduces chemical exposure, and promotes soil health. Organic products often have higher nutritional value and support local farming communities.',
        'verification': 'Annual inspections by USDA-accredited certifying agents, including farm visits, record reviews, and residue testing.'
      },
      'Fair Trade Certified': {
        'name': 'Fair Trade Certified',
        'description': 'Ensures that products are produced under fair labor conditions and that farmers and workers receive fair compensation for their work.',
        'category': 'Fair Trade',
        'criteria': 'Fair wages and working conditions, No child or forced labor, Democratic organization of workers, Environmental protection standards, Community development investments',
        'benefits': 'Improves livelihoods of farmers and workers, supports community development projects, and ensures ethical production practices.',
        'verification': 'Regular audits by independent third-party certifiers, including worker interviews, facility inspections, and documentation reviews.'
      },
      'Energy Star': {
        'name': 'Energy Star',
        'description': 'Identifies energy-efficient products and buildings that meet strict energy performance standards set by the EPA.',
        'category': 'Energy Star',
        'criteria': 'Meets strict energy efficiency guidelines, Third-party testing and verification, Significant energy savings compared to standard models, Maintains performance and features, Comprehensive product testing',
        'benefits': 'Reduces energy consumption and utility bills, lowers greenhouse gas emissions, and helps protect the environment while maintaining product performance.',
        'verification': 'Products must be tested in EPA-recognized laboratories and meet specific energy efficiency criteria for their category.'
      },
      'FSC (Forest Stewardship Council)': {
        'name': 'FSC (Forest Stewardship Council)',
        'description': 'Certifies that wood and paper products come from responsibly managed forests that provide environmental, social, and economic benefits.',
        'category': 'Forest Stewardship',
        'criteria': 'Sustainable forest management practices, Protection of biodiversity and wildlife, Respect for indigenous peoples\' rights, Worker safety and fair labor practices, Chain of custody tracking',
        'benefits': 'Protects forests and wildlife habitats, supports local communities, and ensures sustainable wood and paper production.',
        'verification': 'Independent audits by FSC-accredited certification bodies, including forest assessments, stakeholder consultation, and chain of custody verification.'
      },
      'MSC (Marine Stewardship Council)': {
        'name': 'MSC (Marine Stewardship Council)',
        'description': 'Certifies sustainable seafood that comes from well-managed fisheries that minimize environmental impact.',
        'category': 'Marine Stewardship',
        'criteria': 'Sustainable fish stocks, Minimal environmental impact, Effective fishery management, Chain of custody tracking, Regular reassessment',
        'benefits': 'Helps protect ocean ecosystems, ensures sustainable seafood supply, and supports responsible fishing practices.',
        'verification': 'Comprehensive assessment by independent certifiers, including scientific review, stakeholder consultation, and regular monitoring.'
      },
      'LEED (Leadership in Energy and Environmental Design)': {
        'name': 'LEED (Leadership in Energy and Environmental Design)',
        'description': 'Certifies buildings and communities that are designed, constructed, maintained, and operated for improved environmental and human health performance.',
        'category': 'Building Standards',
        'criteria': 'Sustainable site development, Water efficiency, Energy and atmosphere optimization, Materials and resources selection, Indoor environmental quality, Innovation in design',
        'benefits': 'Reduces environmental impact, improves occupant health and productivity, and provides long-term cost savings through energy efficiency.',
        'verification': 'Third-party verification through the Green Building Certification Institute, including documentation review and on-site inspections.'
      },
      'B Corp Certification': {
        'name': 'B Corp Certification',
        'description': 'Certifies businesses that meet high standards of social and environmental performance, accountability, and transparency.',
        'category': 'Business Standards',
        'criteria': 'Social and environmental impact assessment, Legal accountability, Public transparency, Stakeholder engagement, Continuous improvement',
        'benefits': 'Demonstrates commitment to social and environmental responsibility, attracts conscious consumers and investors, and drives positive change.',
        'verification': 'Comprehensive assessment by B Lab, including documentation review, stakeholder interviews, and regular recertification.'
      },
      'Rainforest Alliance': {
        'name': 'Rainforest Alliance',
        'description': 'Certifies farms, forests, and tourism businesses that meet comprehensive sustainability standards.',
        'category': 'Environmental Protection',
        'criteria': 'Biodiversity conservation, Natural resource management, Worker rights and safety, Community engagement, Climate change mitigation',
        'benefits': 'Protects ecosystems and wildlife, supports local communities, and promotes sustainable business practices.',
        'verification': 'Independent audits by Rainforest Alliance auditors, including on-site assessments and stakeholder consultation.'
      },
      'Custom Certification': {
        'name': '',
        'description': '',
        'category': 'Organic',
        'criteria': '',
        'benefits': '',
        'verification': ''
      }
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: AppColors.success,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Certification',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select a certification type to auto-fill the form, or choose "Custom Certification" to create your own.',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              width: ResponsiveHelper.getScreenWidth(context) * (ResponsiveHelper.isMobile(context) ? 0.95 : 0.8),
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 600,
                maxHeight: ResponsiveHelper.getScreenHeight(context) * (ResponsiveHelper.isMobile(context) ? 0.6 : 0.7),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Certification Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCertificationType,
                      isExpanded: true, // This ensures the dropdown takes full width
                      decoration: InputDecoration(
                        labelText: 'Certification Type',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                      items: certificationTemplates.keys.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) {
                        selectedCertificationType = value!;
                        final template = certificationTemplates[value!]!;
                        
                        // Auto-fill the form fields
                        nameController.text = template['name'] ?? '';
                        descriptionController.text = template['description'] ?? '';
                        selectedCategory = template['category'] ?? 'Organic';
                        criteriaController.text = template['criteria'] ?? '';
                        benefitsController.text = template['benefits'] ?? '';
                        verificationController.text = template['verification'] ?? '';
                        
                        // Reset dropdown selections
                        selectedCriteria = '';
                        selectedBenefits = '';
                        selectedVerification = '';
                        
                        // Trigger rebuild to update category dropdown
                        setState(() {});
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Certification Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Certification Name',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Description
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true, // This ensures the dropdown takes full width
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                      items: kCertificationCategories.where((cat) => cat != 'All').map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) {
                        selectedCategory = value!;
                        setState(() {});
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Criteria Selection
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Certification Criteria',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showOptionsBottomSheet(context, 'Criteria', criteriaOptions, (value) {
                              selectedCriteria = value;
                              criteriaController.text = value;
                              setState(() {});
                            });
                          },
                          child: Text(
                            'Show All',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Wrap(
                      spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      runSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      children: [
                        ...criteriaOptions.take(ResponsiveHelper.isMobile(context) ? 4 : 8).map((criteria) => FilterChip(
                          label: Text(
                            criteria,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            ),
                          ),
                          selected: selectedCriteria == criteria,
                          onSelected: (selected) {
                            if (selected) {
                              selectedCriteria = criteria;
                              criteriaController.text = criteria;
                            } else {
                              selectedCriteria = '';
                              criteriaController.clear();
                            }
                            setState(() {});
                          },
                          selectedColor: AppColors.success.withOpacity(0.2),
                          checkmarkColor: AppColors.success,
                        )).toList(),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Custom Criteria Field
                    TextField(
                      controller: criteriaController,
                      decoration: InputDecoration(
                        labelText: 'Custom Criteria (comma-separated)',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Benefits Selection
                    Text(
                      'Benefits',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Wrap(
                      spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      runSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      children: [
                        ...benefitsOptions.take(ResponsiveHelper.isMobile(context) ? 5 : 10).map((benefit) => FilterChip(
                          label: Text(
                            benefit,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            ),
                          ),
                          selected: selectedBenefits == benefit,
                          onSelected: (selected) {
                            if (selected) {
                              selectedBenefits = benefit;
                              benefitsController.text = benefit;
                            } else {
                              selectedBenefits = '';
                              benefitsController.clear();
                            }
                            setState(() {});
                          },
                          selectedColor: AppColors.success.withOpacity(0.2),
                          checkmarkColor: AppColors.success,
                        )).toList(),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Custom Benefits Field
                    TextField(
                      controller: benefitsController,
                      decoration: InputDecoration(
                        labelText: 'Custom Benefits',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Verification Process Selection
                    Text(
                      'Verification Process',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Wrap(
                      spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      runSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                      children: [
                        ...verificationOptions.take(ResponsiveHelper.isMobile(context) ? 5 : 10).map((verification) => FilterChip(
                          label: Text(
                            verification,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            ),
                          ),
                          selected: selectedVerification == verification,
                          onSelected: (selected) {
                            if (selected) {
                              selectedVerification = verification;
                              verificationController.text = verification;
                            } else {
                              selectedVerification = '';
                              verificationController.clear();
                            }
                            setState(() {});
                          },
                          selectedColor: AppColors.success.withOpacity(0.2),
                          checkmarkColor: AppColors.success,
                        )).toList(),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    
                    // Custom Verification Field
                    TextField(
                      controller: verificationController,
                      decoration: InputDecoration(
                        labelText: 'Custom Verification Process',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear all form fields
                  nameController.clear();
                  descriptionController.clear();
                  criteriaController.clear();
                  benefitsController.clear();
                  verificationController.clear();
                  selectedCategory = 'Organic';
                  selectedCertificationType = 'USDA Organic';
                  selectedCriteria = '';
                  selectedBenefits = '';
                  selectedVerification = '';
                  setState(() {});
                },
                child: Text(
                  'Clear Form',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    color: AppColors.warning,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a certification name',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    // Create new certification
                    final newCertification = Certification(
                      key: '', // Will be set by Firebase
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: selectedCategory,
                      logoUrl: '', // Placeholder for now
                      criteria: criteriaController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      verificationProcess: verificationController.text.trim(),
                      benefits: benefitsController.text.trim(),
                      isVerified: false, // New certifications start as pending
                    );

                    // Save to database
                    await CertificationDAO.addCertification(newCertification);
                    
                    // Refresh the data
                    await _loadData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Certification added successfully!',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to add certification: $e',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                  ),
                ),
                child: Text(
                  'Add Certification',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        ),
      ),
      builder: (context) => Container(
        height: ResponsiveHelper.getScreenHeight(context) * (ResponsiveHelper.isMobile(context) ? 0.5 : 0.6),
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select $title',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 