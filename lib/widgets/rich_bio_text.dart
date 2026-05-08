import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class RichBioText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const RichBioText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Linkify(
      onOpen: (link) async {
        if (link is TagElement) {
          context.push('/search', extra: '#${link.tag}');
        } else if (link is MentionElement) {
          context.push('/search', extra: '@${link.username}');
        } else if (await canLaunchUrl(Uri.parse(link.url))) {
          await launchUrl(Uri.parse(link.url));
        }
      },
      text: text,
      textAlign: textAlign ?? TextAlign.start,
      style: style ?? TextStyle(color: colors.textSecondary, fontSize: 14),
      linkStyle: TextStyle(
        color: colors.primary, // Using primary color for links for better visibility
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      options: const LinkifyOptions(humanize: true),
      linkifiers: const [
        UrlLinkifier(),
        EmailLinkifier(),
        HashtagLinkifier(),
        MentionLinkifier(),
      ],
    );
  }
}

class HashtagLinkifier extends Linkifier {
  const HashtagLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];
    for (var element in elements) {
      if (element is TextElement) {
        // Updated regex to support Arabic characters
        final matches = RegExp(r'#([a-zA-Z0-9_\u0600-\u06FF]+)').allMatches(element.text);
        if (matches.isEmpty) {
          list.add(element);
          continue;
        }

        int lastIndex = 0;
        for (var match in matches) {
          if (match.start > lastIndex) {
            list.add(
              TextElement(element.text.substring(lastIndex, match.start)),
            );
          }
          list.add(TagElement(match.group(0)!, match.group(1)!));
          lastIndex = match.end;
        }
        if (lastIndex < element.text.length) {
          list.add(TextElement(element.text.substring(lastIndex)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}

class TagElement extends LinkableElement {
  final String tag;
  TagElement(String text, this.tag) : super(text, tag);
}

class MentionLinkifier extends Linkifier {
  const MentionLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];
    for (var element in elements) {
      if (element is TextElement) {
        // Updated regex to support Arabic characters
        final matches = RegExp(r'@([a-zA-Z0-9_\u0600-\u06FF]+)').allMatches(element.text);
        if (matches.isEmpty) {
          list.add(element);
          continue;
        }

        int lastIndex = 0;
        for (var match in matches) {
          if (match.start > lastIndex) {
            list.add(
              TextElement(element.text.substring(lastIndex, match.start)),
            );
          }
          list.add(MentionElement(match.group(0)!, match.group(1)!));
          lastIndex = match.end;
        }
        if (lastIndex < element.text.length) {
          list.add(TextElement(element.text.substring(lastIndex)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}

class MentionElement extends LinkableElement {
  final String username;
  MentionElement(String text, this.username) : super(text, username);
}
