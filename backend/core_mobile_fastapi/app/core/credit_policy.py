from dataclasses import dataclass


@dataclass(frozen=True)
class CreditPolicy:
    product: str
    min_amount: float
    max_amount: float
    min_term_months: int
    max_term_months: int
    min_tea: float
    max_tea: float
    default_tea: float
    source: str


PERSONAL_LOAN = CreditPolicy(
    product="Prestamo personal",
    min_amount=1000.0,
    max_amount=60000.0,
    min_term_months=6,
    max_term_months=60,
    min_tea=8.99,
    max_tea=99.90,
    default_tea=32.0,
    source="Interbank TAR-0242, consultado 02/07/2026",
)

BUSINESS_WORKING_CAPITAL = CreditPolicy(
    product="Credito Banca Negocios / PYME",
    min_amount=1.0,
    max_amount=1000000.0,
    min_term_months=1,
    max_term_months=24,
    min_tea=29.65,
    max_tea=55.00,
    default_tea=32.0,
    source="Interbank TAR-0244, TNA convertida a TEA, consultado 02/07/2026",
)


def infer_policy(destino_credito: str | None = None, tipo_negocio: str | None = None) -> CreditPolicy:
    destino = (destino_credito or "").lower()
    negocio = (tipo_negocio or "").lower()
    if negocio or "capital" in destino or "negocio" in destino or "pyme" in destino:
        return BUSINESS_WORKING_CAPITAL
    return PERSONAL_LOAN


def effective_monthly_rate(tea: float) -> float:
    return (1 + tea / 100) ** (1 / 12) - 1


def french_installment(amount: float, term_months: int, tea: float) -> float:
    monthly_rate = effective_monthly_rate(tea)
    if monthly_rate == 0:
        return amount / term_months
    return amount * monthly_rate / (1 - (1 + monthly_rate) ** -term_months)


def normalized_tea(tea: float | None, policy: CreditPolicy) -> float:
    return float(tea if tea is not None else policy.default_tea)


def validate_credit_terms(
    *,
    amount: float,
    term_months: int,
    tea: float | None,
    destino_credito: str | None = None,
    tipo_negocio: str | None = None,
) -> tuple[CreditPolicy, float]:
    policy = infer_policy(destino_credito, tipo_negocio)
    selected_tea = normalized_tea(tea, policy)

    if amount < policy.min_amount or amount > policy.max_amount:
        raise ValueError(
            f"{policy.product}: el monto debe estar entre S/ {policy.min_amount:,.2f} "
            f"y S/ {policy.max_amount:,.2f}."
        )
    if term_months < policy.min_term_months or term_months > policy.max_term_months:
        raise ValueError(
            f"{policy.product}: el plazo debe estar entre {policy.min_term_months} "
            f"y {policy.max_term_months} meses."
        )
    if selected_tea < policy.min_tea or selected_tea > policy.max_tea:
        raise ValueError(
            f"{policy.product}: la TEA debe estar entre {policy.min_tea:.2f}% "
            f"y {policy.max_tea:.2f}%."
        )
    return policy, selected_tea
