package com.imf.detection.flowdetectx.service;

import org.springframework.stereotype.Service;

@Service
public class EvaluationService {

    public double calculerPrecision(int vraisPositifs, int fauxPositifs) {
        int total = vraisPositifs + fauxPositifs;
        if (total == 0) return 0.0;
        return (double) vraisPositifs / total;
    }

    public double calculerRappel(int vraisPositifs, int fauxNegatifs) {
        int total = vraisPositifs + fauxNegatifs;
        if (total == 0) return 0.0;
        return (double) vraisPositifs / total;
    }

    public double calculerF1(double precision, double rappel) {
        if (precision + rappel == 0) return 0.0;
        return 2 * (precision * rappel) / (precision + rappel);
    }

    public double calculerTauxFauxPositifs(int fauxPositifs, int vraisNegatifs) {
        int total = fauxPositifs + vraisNegatifs;
        if (total == 0) return 0.0;
        return (double) fauxPositifs / total;
    }

    /**
     * Calcule VN par soustraction : chaque transaction traitee tombe dans
     * exactement une des 4 categories (VP, FP, FN, VN). Comme VP/FP/FN
     * sont deja comptes par transaction reelle, VN = total - VP - FP - FN.
     * Cela evite d'avoir a persister les transactions normales.
     */
    public int calculerVraisNegatifs(long nbTransactionsTotal, int vp, int fp, int fn) {
        long vn = nbTransactionsTotal - vp - fp - fn;
        return (int) Math.max(0, vn);
    }

    /**
     * Retourne [precision, rappel, f1, tauxFP] en une seule passe.
     */
    public double[] calculerMetriques(int vraisPositifs, int fauxPositifs,
                                        int fauxNegatifs, int vraisNegatifs) {
        double precision = calculerPrecision(vraisPositifs, fauxPositifs);
        double rappel    = calculerRappel(vraisPositifs, fauxNegatifs);
        double f1        = calculerF1(precision, rappel);
        double tauxFP    = calculerTauxFauxPositifs(fauxPositifs, vraisNegatifs);
        return new double[]{precision, rappel, f1, tauxFP};
    }
}