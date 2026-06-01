import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Catálogo visual baseado na carga inicial já existente em copa.sql.
const List<PaisCopa> paisesCopa = [
  PaisCopa('México', 'mx', 'Grupo A'),
  PaisCopa('África do Sul', 'za', 'Grupo A'),
  PaisCopa('Coreia do Sul', 'kr', 'Grupo A'),
  PaisCopa('República Tcheca', 'cz', 'Grupo A'),
  PaisCopa('Canadá', 'ca', 'Grupo B'),
  PaisCopa('Bósnia e Herzegovina', 'ba', 'Grupo B'),
  PaisCopa('Catar', 'qa', 'Grupo B'),
  PaisCopa('Suíça', 'ch', 'Grupo B'),
  PaisCopa('Brasil', 'br', 'Grupo C'),
  PaisCopa('Marrocos', 'ma', 'Grupo C'),
  PaisCopa('Haiti', 'ht', 'Grupo C'),
  PaisCopa('Escócia', 'gb-sct', 'Grupo C'),
  PaisCopa('Estados Unidos', 'us', 'Grupo D'),
  PaisCopa('Paraguai', 'py', 'Grupo D'),
  PaisCopa('Austrália', 'au', 'Grupo D'),
  PaisCopa('Turquia', 'tr', 'Grupo D'),
  PaisCopa('Alemanha', 'de', 'Grupo E'),
  PaisCopa('Curaçao', 'cw', 'Grupo E'),
  PaisCopa('Costa do Marfim', 'ci', 'Grupo E'),
  PaisCopa('Equador', 'ec', 'Grupo E'),
  PaisCopa('Holanda', 'nl', 'Grupo F'),
  PaisCopa('Japão', 'jp', 'Grupo F'),
  PaisCopa('Suécia', 'se', 'Grupo F'),
  PaisCopa('Tunísia', 'tn', 'Grupo F'),
  PaisCopa('Bélgica', 'be', 'Grupo G'),
  PaisCopa('Egito', 'eg', 'Grupo G'),
  PaisCopa('Irã', 'ir', 'Grupo G'),
  PaisCopa('Nova Zelândia', 'nz', 'Grupo G'),
  PaisCopa('Espanha', 'es', 'Grupo H'),
  PaisCopa('Cabo Verde', 'cv', 'Grupo H'),
  PaisCopa('Arábia Saudita', 'sa', 'Grupo H'),
  PaisCopa('Uruguai', 'uy', 'Grupo H'),
  PaisCopa('França', 'fr', 'Grupo I'),
  PaisCopa('Senegal', 'sn', 'Grupo I'),
  PaisCopa('Iraque', 'iq', 'Grupo I'),
  PaisCopa('Noruega', 'no', 'Grupo I'),
  PaisCopa('Argentina', 'ar', 'Grupo J'),
  PaisCopa('Argélia', 'dz', 'Grupo J'),
  PaisCopa('Áustria', 'at', 'Grupo J'),
  PaisCopa('Jordânia', 'jo', 'Grupo J'),
  PaisCopa('Portugal', 'pt', 'Grupo K'),
  PaisCopa('RD Congo', 'cd', 'Grupo K'),
  PaisCopa('Uzbequistão', 'uz', 'Grupo K'),
  PaisCopa('Colômbia', 'co', 'Grupo K'),
  PaisCopa('Inglaterra', 'gb-eng', 'Grupo L'),
  PaisCopa('Croácia', 'hr', 'Grupo L'),
  PaisCopa('Gana', 'gh', 'Grupo L'),
  PaisCopa('Panamá', 'pa', 'Grupo L'),
];

PaisCopa paisCopaPorNome(String nome) {
  return paisesCopa.firstWhere(
    (pais) => pais.nome.toLowerCase() == nome.toLowerCase(),
    orElse: () => PaisCopa(nome, '', ''),
  );
}

class PaisCopa {
  final String nome;
  final String codigo;
  final String grupo;

  const PaisCopa(this.nome, this.codigo, this.grupo);
}

class CopaFlagImage extends StatelessWidget {
  final PaisCopa pais;
  final double width;
  final double height;

  const CopaFlagImage({
    super.key,
    required this.pais,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (pais.codigo.isEmpty) {
      return _flagFrame(
        const Icon(Icons.flag, color: Color(0xFF64748B), size: 18),
      );
    }

    return _flagFrame(
      SvgPicture.network(
        'https://flagcdn.com/${pais.codigo}.svg'.toLowerCase(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        placeholderBuilder: (context) => SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: width,
          height: height,
          child: const Icon(Icons.flag, color: Color(0xFF64748B), size: 18),
        ),
      ),
    );
  }

  Widget _flagFrame(Widget child) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ClipRect(
          child: ColoredBox(color: const Color(0xFFF8FAFC), child: child),
        ),
      ),
    );
  }
}
