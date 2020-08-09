const std = @import("std");
const date = @import("date.zig");

pub const date_time_options = date.DateTimeOptions{
    .months_short_cap = [_][]const u8{
        "Jan",
        "Fev",
        "Mar",
        "Abr",
        "Mai",
        "Jun",
        "Jul",
        "Ago",
        "Set",
        "Out",
        "Nov",
        "Dez",
    },
    .months_short_low = [_][]const u8{
        "jan",
        "fev",
        "mar",
        "abr",
        "mai",
        "jun",
        "jul",
        "ago",
        "set",
        "out",
        "nov",
        "dez",
    },
    .months_cap = [_][]const u8{
        "Janeiro",
        "Fevereiro",
        "Março",
        "Abril",
        "Maio",
        "Junho",
        "Julho",
        "Agosto",
        "Setembro",
        "Outubro",
        "Novembro",
        "Dezembro",
    },
    .months_low = [_][]const u8{
        "janeiro",
        "fevereiro",
        "março",
        "abril",
        "maio",
        "junho",
        "julho",
        "agosto",
        "setembro",
        "outubro",
        "novembro",
        "dezembro",
    },
    .am_low = "am",
    .pm_low = "pm",
    .am_up = "AM",
    .pm_up = "PM",
    .weekdays_short_cap = [_][]const u8{
        "Dom",
        "Seg",
        "Ter",
        "Qua",
        "Qui",
        "Sex",
        "Sáb",
    },
    .weekdays_short_low = [_][]const u8{
        "dom",
        "seg",
        "ter",
        "qua",
        "qui",
        "sex",
        "sáb",
    },
    .weekdays_cap = [_][]const u8{
        "Domingo",
        "Segunda",
        "Terça",
        "Quarta",
        "Quinta",
        "Sexta",
        "Sábado",
    },
    .weekdays_low = [_][]const u8{
        "domingo",
        "segunda",
        "terça",
        "quarta",
        "quinta",
        "sexta",
        "sábado",
    },
};

pub fn main() void {
    const w = date.GregorianDateTime.now().getDateTime();
    var out = std.io.getStdOut().writer();

    w.format("y", out) catch {};
    out.writeByte('\n') catch {};

    w.format("yy", out) catch {};
    out.writeByte('\n') catch {};

    w.format("yyy", out) catch {};
    out.writeByte('\n') catch {};

    w.format("yyyy", out) catch {};
    out.writeByte('\n') catch {};

    w.format("M", out) catch {};
    out.writeByte('\n') catch {};

    w.format("MM", out) catch {};
    out.writeByte('\n') catch {};

    w.format("MMM", out) catch {};
    out.writeByte('\n') catch {};

    w.format("MMm", out) catch {};
    out.writeByte('\n') catch {};

    w.format("MMMM", out) catch {};
    out.writeByte('\n') catch {};

    w.format("MMmm", out) catch {};
    out.writeByte('\n') catch {};

    w.format("d", out) catch {};
    out.writeByte('\n') catch {};

    w.format("dd", out) catch {};
    out.writeByte('\n') catch {};

    w.format("h", out) catch {};
    out.writeByte('\n') catch {};

    w.format("H", out) catch {};
    out.writeByte('\n') catch {};

    w.format("hh", out) catch {};
    out.writeByte('\n') catch {};

    w.format("HH", out) catch {};
    out.writeByte('\n') catch {};

    w.format("a", out) catch {};
    out.writeByte('\n') catch {};

    w.format("A", out) catch {};
    out.writeByte('\n') catch {};

    w.format("m", out) catch {};
    out.writeByte('\n') catch {};

    w.format("mm", out) catch {};
    out.writeByte('\n') catch {};

    w.format("s", out) catch {};
    out.writeByte('\n') catch {};

    w.format("ss", out) catch {};
    out.writeByte('\n') catch {};

    w.format("N", out) catch {};
    out.writeByte('\n') catch {};

    w.format("n", out) catch {};
    out.writeByte('\n') catch {};

    w.format("nn", out) catch {};
    out.writeByte('\n') catch {};

    w.format("nnn", out) catch {};
    out.writeByte('\n') catch {};

    w.format("liter4l\n", out) catch {};
    w.format("", out) catch {};
}
