//
//  PhoneInfoView.swift
//  SystemValuesPhone
//
//  Created by Algun Romper  on 27.12.2023.
//

import SwiftUI

struct PhoneInfoView: View {
    var type: String
    var info: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(type)
                        .fontWeight(/*@START_MENU_TOKEN@*/.semibold/*@END_MENU_TOKEN@*/)
                    Text(info)
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                }
                Spacer()
            }
            Text(value)
                .fontWeight(.bold)
        }
        .padding(15)
        .background(.white)
        .cornerRadius(21)
        .shadow(radius: 5)
    }
}

struct PhoneInfoView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneInfoView(type: "RAM", info: "", value: "1500")
    }
}
