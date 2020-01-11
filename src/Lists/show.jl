#=
 HOW TO SHOW AN S-EXPRESSION
 ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

  • cap lines to 80 characters (if possible)
  • overflow all s-expressions if not
  • if head is short [≤ 3], then keep first argument on the same line

 performance isn’t a concern but if it’s too shitty we can consider ropes
=#

# TODO: missing lots of native s-expression types here. also non-native types
# TODO: improper list printing
"""
Convenience function to produce compact strings from (proper) lists of lisp objects.
"""
unparse(α::List) = "(" * join(unparse.(α), " ") * ")"
unparse(b::Bool) = b ? "#t" : "#f"
unparse(s::Symbol) = string(s)
unparse(s::AbstractString) = repr(String(s))
unparse(i::Integer) = string(BigInt(i))
unparse(::Nothing) = "#<void>"

struct ShowListContext
    indent::Int
    limit::Int
end

# arbitrarily decide that there’s always room for 5 more
space(ctx::ShowListContext) = max(5, ctx.limit - ctx.indent)

# performance is really not our concern
sindent(ctx::ShowListContext) = " " ^ ctx.indent

indented(ctx::ShowListContext, i=2) = ShowListContext(ctx.indent + i, ctx.limit)

sprintwidth(α) = sum(charwidth(c) for c in unparse(α))

spprintall(ctx::ShowListContext, α) = join((β -> spprint(ctx, β)) ∘ α, '\n')

spprint(ctx::ShowListContext, α) = sindent(ctx) * unparse(α)

function spprint(ctx::ShowListContext, α::Cons)
    if sprintwidth(α) ≤ space(ctx) || length(α) ≤ 1
        # verbatim
        sindent(ctx) * unparse(α)
    elseif (spw = sprintwidth(car(α))) ≤ 3 && length(α) ≥ 3
        # (car cadr ¶ ...) format
        ctxi = indented(ctx, spw + 2)
        sindent(ctx) * "(" * unparse(car(α)) * " " * unparse(cadr(α)) * "\n" *
                spprintall(ctxi, cddr(α)) * ")"
    else
        # (car ¶ ...) format
        ctxi = indented(ctx, 2)
        sindent(ctx) * "(" * unparse(car(α)) * "\n" *
                spprintall(ctxi, cdr(α)) * ")"
    end
end

spprint(α::List) = spprint(ShowListContext(0, 80), α)

function Base.show(io::IO, α::List)
    if get(io, :multiline, false)
        print(io, spprint(α))
    else
        print(io, unparse(α))
    end
end
